import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../core/design_system.dart';
import '../core/geo.dart';
import '../core/image_compress.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/member_provider.dart';
import '../providers/voter_provider.dart';
import '../core/ph_time.dart';
import 'form_fields.dart';

enum MemberFormStep {
  voterSearch, // Step 1: Find Voter Record (Screenshot 2)
  memberForm, // Step 2: Complete Intake Form (Screenshot 3 & 4)
}

class MemberFormDialog extends ConsumerStatefulWidget {
  final FamilyMember? existing;
  final Household? presetHousehold;

  const MemberFormDialog({
    super.key,
    this.existing,
    this.presetHousehold,
  });

  @override
  ConsumerState<MemberFormDialog> createState() => _MemberFormDialogState();
}

class DependentMemberData {
  final TextEditingController lastNameCtrl;
  final TextEditingController firstNameCtrl;
  final TextEditingController middleNameCtrl;
  final TextEditingController contactCtrl;
  final TextEditingController phicNoCtrl;
  DateTime? birthDate;
  // Used to scroll this row back into view after a voter search
  final GlobalKey cardKey = GlobalKey();
  final Set<String> sectors = {'General'};
  String? yearLevel;
  String? gender; // 'Male' / 'Female'
  bool trucareMember = false;
  bool phicMember = false;

  // True when Senior Citizen was ticked by the birthday rule rather than by hand
  bool seniorAutoSet = false;

  // Voter-registry match check for this row
  Timer? matchDebounce;
  List<VoterSearchResult> possibleMatches = [];
  bool fromVoterRecord = false;

  // Layout: folded into a one-line summary, and whether the optional fields are shown
  bool expanded = true;
  bool showMore = false;

  // Birthday box holds a complete but out-of-range date (checked even while the row is folded)
  bool birthdayInvalid = false;

  DependentMemberData({
    String lastName = '',
    String firstName = '',
    String middleName = '',
    String contact = '',
  })  : lastNameCtrl = TextEditingController(text: lastName),
        firstNameCtrl = TextEditingController(text: firstName),
        middleNameCtrl = TextEditingController(text: middleName),
        contactCtrl = TextEditingController(text: contact),
        phicNoCtrl = TextEditingController();

  void dispose() {
    lastNameCtrl.dispose();
    firstNameCtrl.dispose();
    middleNameCtrl.dispose();
    contactCtrl.dispose();
    phicNoCtrl.dispose();
    matchDebounce?.cancel();
  }
}

class _MemberFormDialogState extends ConsumerState<MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Current Step Flow
  late MemberFormStep _currentStep;

  // STEP 1: Voter Search Controls
  final _searchLastNameCtrl = TextEditingController();
  final _searchFirstNameCtrl = TextEditingController();
  final _searchMiddleNameCtrl = TextEditingController();
  String _searchLgu = 'VALENCIA CITY';
  String _searchBarangay = 'All Barangays';
  Timer? _searchDebounce;

  List<VoterSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _searchPerformed = false;
  VoterSearchResult? _selectedVoter;
  // When set, a voter picked in Step 1 fills this household-member row instead of the primary member
  int? _voterSearchDependentIndex;

  // Manual entry: voter records that match the typed name, offered for review
  Timer? _matchDebounce;
  List<VoterSearchResult> _possibleMatches = [];

  // STEP 2: Member Form Controls
  final _lastNameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _phicNoCtrl = TextEditingController();

  DateTime? _birthDate;
  // Starts at today, except when joining a household (left blank so staff enter it deliberately)
  DateTime? _membershipDate = phToday();

  // Sectors
  final Set<String> _selectedSectors = {'General'};
  // True when Senior Citizen was ticked by the birthday rule rather than by hand
  bool _seniorAutoChecked = false;
  String? _yearLevel;
  String? _gender; // 'Male' / 'Female', required
  static const _genders = ['Male', 'Female'];
  static const _yearLevels = ['Elementary', 'High School', 'College'];
  final List<String> _sectorOptions = [
    'General',
    'Youth',
    'Student',
    'Senior Citizen',
    'PWD',
    'LGBTQ+',
    'Solo Parent',
    'Indigenous People',
  ];

  // Affiliations
  bool _trucareMember = false;
  bool _phicMember = false;

  // Household & Location
  Household? _selectedHousehold;
  String _lgu = '';
  String _barangay = '';
  String _purok = '';
  String? _purokId;

  // Status & Qualifications
  String _listingStatus = 'TROPA MEMBER';
  bool _isHouseholdLeader = false;
  // Registered voter = a record from the `voters` table was selected (read-only in the form)
  bool _isVoter = false;

  // Dependent Members
  final List<DependentMemberData> _dependentMembers = [];

  // Avatar Upload
  Uint8List? _avatarBytes;
  String? _avatarName;
  bool _isUploadingPhoto = false;
  bool _isSaving = false;
  // Last member saved in this dialog; returned on close so the caller (e.g. household view) refreshes
  FamilyMember? _savedMember;

  // Layout state
  bool _showMoreDetails = false; // optional contact / TRU Care / PhilHealth fields
  bool _sidebarVisible = false; // summary panel, only on wide screens

  // LGU / barangay options come from the distinct values in the `locations` table
  List<LocationOption> get _locations => ref.read(locationsProvider).valueOrNull ?? const [];

  List<String> get _lgus => ({
        for (final l in _locations)
          if (l.lgu.isNotEmpty) l.lgu
      }).toList()
        ..sort();

  List<String> _barangaysFor(String lgu) => ({
        for (final l in _locations)
          if (l.barangay.isNotEmpty && (lgu.isEmpty || lgu == 'All LGUs' || l.lgu == lgu)) l.barangay
      }).toList()
        ..sort();

  /// Keeps a saved/pre-filled value selectable even if it isn't (yet) in the loaded options.
  List<String> _withCurrent(List<String> options, String current) =>
      current.isEmpty || options.contains(current) ? options : [current, ...options];

  /// `locations.id` for the selected LGU + barangay; puroks hang off this id.
  String? get _locationId {
    if (_lgu.isEmpty || _barangay.isEmpty) return null;
    for (final l in _locations) {
      if (l.lgu == _lgu && l.barangay == _barangay && l.id.isNotEmpty) return l.id;
    }
    return null;
  }

  /// The purok id to save: the one picked, or a lookup by name for pre-filled puroks.
  String? get _resolvedPurokId {
    if (_purokId != null || _purok.isEmpty) return _purokId;
    final locationId = _locationId;
    if (locationId == null) return null;
    for (final p in ref.read(puroksProvider(locationId)).valueOrNull ?? const <({String id, String name})>[]) {
      if (p.name.toUpperCase() == _purok.toUpperCase()) return p.id;
    }
    return null;
  }

  /// Age in whole years as of today.
  static int _ageOn(DateTime birth) {
    final now = phToday();
    var age = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) age--;
    return age;
  }

  /// Ticks Senior Citizen at 60+; unticks it below 60 only if it was ticked automatically.
  void _applySeniorRule() {
    if (_birthDate == null) return;
    final isSenior = _ageOn(_birthDate!) >= 60;
    if (isSenior && !_selectedSectors.contains('Senior Citizen')) {
      _selectedSectors.add('Senior Citizen');
      _seniorAutoChecked = true;
    } else if (!isSenior && _seniorAutoChecked) {
      _selectedSectors.remove('Senior Citizen');
      if (_selectedSectors.isEmpty) _selectedSectors.add('General');
      _seniorAutoChecked = false;
    }
  }

  void _applyDependentSeniorRule(DependentMemberData dep) {
    if (dep.birthDate == null) return;
    final isSenior = _ageOn(dep.birthDate!) >= 60;
    if (isSenior && !dep.sectors.contains('Senior Citizen')) {
      dep.sectors.add('Senior Citizen');
      dep.seniorAutoSet = true;
    } else if (!isSenior && dep.seniorAutoSet) {
      dep.sectors.remove('Senior Citizen');
      if (dep.sectors.isEmpty) dep.sectors.add('General');
      dep.seniorAutoSet = false;
    }
  }

  /// Manual sector tick/untick on a household member row (at least one sector stays selected).
  void _setDependentSector(DependentMemberData dep, String sector, bool selected) {
    setState(() {
      if (selected) {
        dep.sectors.add(sector);
      } else if (dep.sectors.length > 1) {
        dep.sectors.remove(sector);
      }
      if (sector == 'Senior Citizen') dep.seniorAutoSet = false;
      if (!dep.sectors.contains('Student')) dep.yearLevel = null;
    });
  }

  /// Manual sector tick/untick on the main member (at least one sector stays selected).
  void _setSector(String sector, bool selected) {
    setState(() {
      if (selected) {
        _selectedSectors.add(sector);
      } else if (_selectedSectors.length > 1) {
        _selectedSectors.remove(sector);
      }
      if (sector == 'Senior Citizen') _seniorAutoChecked = false;
      if (!_selectedSectors.contains('Student')) _yearLevel = null;
    });
  }

  /// Sectors are stored as one comma list (e.g. "Student, PWD"), in checkbox order.
  /// "General" is only kept when nothing more specific is ticked.
  String _joinSectors(Set<String> selected) {
    final specific = _sectorOptions.where((o) => o != 'General' && selected.contains(o)).toList();
    return specific.isEmpty ? 'General' : specific.join(', ');
  }

  /// Reverse of [_joinSectors]; tolerates older single-value rows.
  Set<String> _splitSectors(String? stored) {
    final parts = (stored ?? '').split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toSet();
    return parts.isEmpty ? {'General'} : parts;
  }

  @override
  void initState() {
    super.initState();
    _selectedHousehold = widget.presetHousehold;

    if (widget.existing != null) {
      // Direct Edit Mode: bypass search
      _currentStep = MemberFormStep.memberForm;
      final e = widget.existing!;
      _lastNameCtrl.text = e.lastname;
      _firstNameCtrl.text = e.firstname;
      _middleNameCtrl.text = e.middlename ?? '';
      _contactCtrl.text = _displayContact(e.contactNumber);
      _phicNoCtrl.text = e.phicNo ?? '';
      _birthDate = e.birthDate;
      _membershipDate = e.membershipDate ?? phToday();
      _selectedSectors
        ..clear()
        ..addAll(_splitSectors(e.sector));
      _yearLevel = e.yearLevel;
      _gender = _genders.contains(e.gender) ? e.gender : null;
      _trucareMember = e.trucareMember ?? false;
      _phicMember = e.phicMember ?? false;
      _lgu = e.lgu.trim().toUpperCase();
      _barangay = e.barangay.trim().toUpperCase();
      _purok = e.purok.trim();
      _purokId = e.purokId;
      _listingStatus = (e.listingStatus == null || e.listingStatus == 'MEMBER' || e.listingStatus == 'COOP')
          ? 'TROPA MEMBER'
          : e.listingStatus!;
      _isHouseholdLeader = e.isHouseholdLeader;
      _isVoter = e.isVoter;
    } else {
      // New Member Registration: Step 1 Search First!
      _currentStep = MemberFormStep.voterSearch;
      if (widget.presetHousehold != null) {
        _membershipDate = null;
        _lgu = widget.presetHousehold!.lgu.trim().toUpperCase();
        _barangay = widget.presetHousehold!.barangay.trim().toUpperCase();
        _purok = widget.presetHousehold!.purok.trim();
        _purokId = widget.presetHousehold!.purokId;
      }
    }

    for (final c in [_lastNameCtrl, _firstNameCtrl, _middleNameCtrl]) {
      c.addListener(_onPrimaryNameChanged);
    }

    _loadHouseholds();
  }

  void _onPrimaryNameChanged() {
    // Household name, sidebar and summaries all reflect the typed name
    if (mounted) setState(() {});
    _scheduleMatchCheck();
  }

  /// Only new, manually-entered members are checked against the voter registry.
  bool get _shouldCheckMatches =>
      widget.existing == null && _selectedVoter == null && _currentStep == MemberFormStep.memberForm;

  void _scheduleMatchCheck() {
    _matchDebounce?.cancel();
    if (!_shouldCheckMatches) return;
    _matchDebounce = Timer(const Duration(milliseconds: 500), _checkPossibleMatches);
  }

  Future<void> _checkPossibleMatches() async {
    final lastName = _lastNameCtrl.text.trim();
    final firstName = _firstNameCtrl.text.trim();
    final middleName = _middleNameCtrl.text.trim();
    if (lastName.isEmpty || firstName.isEmpty) {
      if (_possibleMatches.isNotEmpty && mounted) setState(() => _possibleMatches = []);
      return;
    }

    try {
      final results = await ref.read(supabaseServiceProvider).searchVoterRegistry(
            lastName: lastName,
            firstName: firstName,
            middleName: middleName.isNotEmpty ? middleName : null,
          );
      // Drop the result if the user kept typing or picked a voter meanwhile
      final unchanged = lastName == _lastNameCtrl.text.trim() &&
          firstName == _firstNameCtrl.text.trim() &&
          middleName == _middleNameCtrl.text.trim();
      if (mounted && unchanged && _shouldCheckMatches) {
        setState(() => _possibleMatches = results);
      }
    } catch (_) {}
  }

  void _reviewPossibleMatches() {
    _searchDebounce?.cancel();
    setState(() {
      _voterSearchDependentIndex = null;
      _searchLastNameCtrl.text = _lastNameCtrl.text.trim();
      _searchFirstNameCtrl.text = _firstNameCtrl.text.trim();
      _searchMiddleNameCtrl.text = _middleNameCtrl.text.trim();
      final lgu = _possibleMatches.first.lgu;
      if (lgu.trim().isNotEmpty) _searchLgu = lgu.trim().toUpperCase();
      _searchBarangay = 'All Barangays';
      _searchResults = _possibleMatches;
      _searchPerformed = true;
      _isSearching = false;
      _currentStep = MemberFormStep.voterSearch;
    });
  }

  /// Household name for a new household led by this member: "LASTNAME, FIRSTNAME MIDDLENAME FAMILY".
  String get _generatedHouseholdName {
    final last = _lastNameCtrl.text.trim().toUpperCase();
    final given = [_firstNameCtrl.text, _middleNameCtrl.text]
        .map((n) => n.trim().toUpperCase())
        .where((n) => n.isNotEmpty)
        .join(' ');
    if (last.isEmpty && given.isEmpty) return '';
    return '${[last, given].where((n) => n.isNotEmpty).join(', ')} FAMILY';
  }

  /// A new household is created on save only for a new leader who isn't already attached to one.
  /// Opened from a household's "Add TROPA Member": the member joins that household,
  /// so they can't be its leader and its location is fixed.
  bool get _joiningHousehold => widget.presetHousehold != null && widget.existing == null;

  bool get _createsNewHousehold => _isHouseholdLeader && widget.existing == null && widget.presetHousehold == null;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _matchDebounce?.cancel();
    _searchLastNameCtrl.dispose();
    _searchFirstNameCtrl.dispose();
    _searchMiddleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _contactCtrl.dispose();
    _phicNoCtrl.dispose();
    for (var d in _dependentMembers) {
      d.dispose();
    }
    super.dispose();
  }

  /// In edit mode, look up the member's current household so its name can be shown.
  Future<void> _loadHouseholds() async {
    final householdId = widget.existing?.householdId;
    if (_selectedHousehold != null || householdId == null) return;
    final household = await ref.read(supabaseServiceProvider).getHouseholdById(householdId);
    if (mounted && household != null) setState(() => _selectedHousehold = household);
  }

  void _onSearchFieldChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _executeVoterSearch();
    });
  }

  Future<void> _executeVoterSearch() async {
    final lastName = _searchLastNameCtrl.text.trim();
    final firstName = _searchFirstNameCtrl.text.trim();
    final middleName = _searchMiddleNameCtrl.text.trim();

    if (lastName.isEmpty && firstName.isEmpty && middleName.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchPerformed = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchPerformed = true;
    });

    try {
      final service = ref.read(supabaseServiceProvider);
      final results = await service.searchVoterRegistry(
        lastName: lastName.isNotEmpty ? lastName : null,
        firstName: firstName.isNotEmpty ? firstName : null,
        middleName: middleName.isNotEmpty ? middleName : null,
        lgu: _searchLgu,
        barangay: _searchBarangay != 'All Barangays' ? _searchBarangay : null,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  void _selectVoterAndProceed(VoterSearchResult voter) {
    final depIndex = _voterSearchDependentIndex;
    if (depIndex != null && depIndex < _dependentMembers.length) {
      final dep = _dependentMembers[depIndex];
      dep.fromVoterRecord = true;
      dep.matchDebounce?.cancel();
      setState(() {
        dep.possibleMatches = [];
        dep.lastNameCtrl.text = voter.lastName;
        dep.firstNameCtrl.text = voter.firstName;
        dep.middleNameCtrl.text = voter.middleName ?? '';
        dep.contactCtrl.text = _displayContact(voter.contactNumber);
        dep.phicNoCtrl.text = voter.phicNo ?? '';
        if (voter.birthDate != null) dep.birthDate = DateTime.tryParse(voter.birthDate!);
        if (voter.sector != null && voter.sector!.isNotEmpty) {
          dep.sectors
            ..clear()
            ..addAll(_splitSectors(voter.sector));
        }
        _applyDependentSeniorRule(dep);
        _voterSearchDependentIndex = null;
        _currentStep = MemberFormStep.memberForm;
      });
      _revealDependent(dep);
      return;
    }

    _matchDebounce?.cancel();
    setState(() {
      _selectedVoter = voter;
      _possibleMatches = [];

      // Populate personal info
      _lastNameCtrl.text = voter.lastName;
      _firstNameCtrl.text = voter.firstName;
      _middleNameCtrl.text = voter.middleName ?? '';
      _contactCtrl.text = _displayContact(voter.contactNumber);
      _phicNoCtrl.text = voter.phicNo ?? '';

      if (voter.birthDate != null) {
        _birthDate = DateTime.tryParse(voter.birthDate!);
      }
      // Joining a household: membership date stays blank for staff to enter
      if (voter.membershipDate != null && !_joiningHousehold) {
        _membershipDate = DateTime.tryParse(voter.membershipDate!) ?? phToday();
      }

      if (voter.sector != null && voter.sector!.isNotEmpty) {
        _selectedSectors
          ..clear()
          ..addAll(_splitSectors(voter.sector));
      }
      _seniorAutoChecked = false;
      _applySeniorRule();

      // Affiliations are always confirmed manually during intake
      _trucareMember = false;
      _phicMember = false;

      // Location (kept as the household's when joining one)
      if (!_joiningHousehold) {
        if (voter.lgu.trim().isNotEmpty) {
          _lgu = voter.lgu.trim().toUpperCase();
        }
        if (voter.barangay.trim().isNotEmpty) {
          _barangay = voter.barangay.trim().toUpperCase();
        }
        if (voter.purok != null && voter.purok!.trim().isNotEmpty) {
          _purok = voter.purok!.trim();
          _purokId = null;
        }
      }

      // Status
      _listingStatus = (voter.status.toUpperCase() == 'MEMBER' || voter.status.toUpperCase() == 'COOP')
          ? 'TROPA MEMBER'
          : voter.status;
      _isVoter = true; // picked from the voters table

      // Proceed to Step 2
      _currentStep = MemberFormStep.memberForm;
    });
  }

  void _skipToManualForm() {
    final depIndex = _voterSearchDependentIndex;
    if (depIndex != null && depIndex < _dependentMembers.length) _revealDependent(_dependentMembers[depIndex]);
    setState(() {
      // Searching for a household member: just return to the form, keep the primary voter
      if (_voterSearchDependentIndex == null) {
        _selectedVoter = null;
        if (widget.existing == null) _isVoter = false;
      }
      _voterSearchDependentIndex = null;
      _currentStep = MemberFormStep.memberForm;
    });
    _scheduleMatchCheck();
  }

  /// After returning from a household-member voter search, bring that member's card into view.
  void _revealDependent(DependentMemberData dep) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = dep.cardKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(ctx, alignment: 0.1, duration: const Duration(milliseconds: 250));
      }
    });
  }

  void _searchVoterForDependent(int index) {
    final dep = _dependentMembers[index];
    _searchDebounce?.cancel();
    setState(() {
      _voterSearchDependentIndex = index;
      _searchLastNameCtrl.text = dep.lastNameCtrl.text.trim();
      _searchFirstNameCtrl.text = dep.firstNameCtrl.text.trim();
      _searchMiddleNameCtrl.text = dep.middleNameCtrl.text.trim();
      _searchResults = [];
      _searchPerformed = false;
      _currentStep = MemberFormStep.voterSearch;
    });
    _executeVoterSearch();
  }

  void _backToSearch() {
    setState(() {
      _currentStep = MemberFormStep.voterSearch;
    });
  }

  void _addDependentRow() {
    final dep = DependentMemberData();
    for (final c in [dep.lastNameCtrl, dep.firstNameCtrl, dep.middleNameCtrl]) {
      c.addListener(() {
        _scheduleDependentMatchCheck(dep);
        if (mounted) setState(() {}); // keeps the folded summary and sidebar current
      });
    }
    setState(() {
      for (final d in _dependentMembers) {
        d.expanded = false;
      }
      _dependentMembers.add(dep);
    });
  }

  void _scheduleDependentMatchCheck(DependentMemberData dep) {
    dep.matchDebounce?.cancel();
    if (dep.fromVoterRecord) return;
    dep.matchDebounce = Timer(const Duration(milliseconds: 500), () => _checkDependentMatches(dep));
  }

  Future<void> _checkDependentMatches(DependentMemberData dep) async {
    final lastName = dep.lastNameCtrl.text.trim();
    final firstName = dep.firstNameCtrl.text.trim();
    final middleName = dep.middleNameCtrl.text.trim();
    if (lastName.isEmpty || firstName.isEmpty) {
      if (dep.possibleMatches.isNotEmpty && mounted) setState(() => dep.possibleMatches = []);
      return;
    }

    try {
      final results = await ref.read(supabaseServiceProvider).searchVoterRegistry(
            lastName: lastName,
            firstName: firstName,
            middleName: middleName.isNotEmpty ? middleName : null,
          );
      final stillThere = _dependentMembers.contains(dep);
      final unchanged = lastName == dep.lastNameCtrl.text.trim() &&
          firstName == dep.firstNameCtrl.text.trim() &&
          middleName == dep.middleNameCtrl.text.trim();
      if (mounted && stillThere && unchanged && !dep.fromVoterRecord) {
        setState(() => dep.possibleMatches = results);
      }
    } catch (_) {}
  }

  void _reviewDependentMatches(DependentMemberData dep) {
    final index = _dependentMembers.indexOf(dep);
    if (index < 0 || dep.possibleMatches.isEmpty) return;
    _searchDebounce?.cancel();
    setState(() {
      _voterSearchDependentIndex = index;
      _searchLastNameCtrl.text = dep.lastNameCtrl.text.trim();
      _searchFirstNameCtrl.text = dep.firstNameCtrl.text.trim();
      _searchMiddleNameCtrl.text = dep.middleNameCtrl.text.trim();
      final lgu = dep.possibleMatches.first.lgu;
      if (lgu.trim().isNotEmpty) _searchLgu = lgu.trim().toUpperCase();
      _searchBarangay = 'All Barangays';
      _searchResults = dep.possibleMatches;
      _searchPerformed = true;
      _isSearching = false;
      _currentStep = MemberFormStep.voterSearch;
    });
  }

  void _removeDependentRow(int index) {
    setState(() {
      final item = _dependentMembers.removeAt(index);
      _voterSearchDependentIndex = null;
      item.dispose();
    });
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.first.bytes != null) {
      final rawBytes = result.files.first.bytes!;
      setState(() => _isUploadingPhoto = true);
      try {
        final compressed = await compressPhoto(rawBytes);
        setState(() {
          _avatarBytes = compressed;
          _avatarName = result.files.first.name;
        });
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('That photo could not be read. Try a different JPG or PNG.'),
            backgroundColor: TropaColors.error,
          ));
        }
      } finally {
        if (mounted) setState(() => _isUploadingPhoto = false);
      }
    }
  }

  /// What's still missing on a household member row (empty rows are ignored on save).
  List<String> _dependentProblems(DependentMemberData d) {
    final last = d.lastNameCtrl.text.trim();
    final first = d.firstNameCtrl.text.trim();
    if (last.isEmpty && first.isEmpty) return const [];
    return [
      if (last.isEmpty) 'last name',
      if (first.isEmpty) 'first name',
      if (d.sectors.contains('Student') && d.yearLevel == null) 'year level',
      if (d.birthdayInvalid || d.birthDate == null) 'birthday',
      if (d.gender == null) 'gender',
      if (_contactError(d.contactCtrl.text) != null) 'contact number',
    ];
  }

  // ---------------------------------------------------------------------------
  // PH mobile numbers: shown as 0917 123 4567, saved as 09171234567
  // ---------------------------------------------------------------------------

  /// Digits only, normalised to the 09… form (+63 9… / 639… / 9… are accepted).
  static String _phMobileDigits(String text) {
    var d = text.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('63')) d = '0${d.substring(2)}';
    if (d.startsWith('9')) d = '0$d';
    return d;
  }

  static bool _isValidPhMobile(String text) => RegExp(r'^09\d{9}$').hasMatch(_phMobileDigits(text));

  static String _formatPhMobile(String digits) {
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 4 || i == 7) b.write(' ');
      b.write(digits[i]);
    }
    return b.toString();
  }

  /// Pre-filled numbers are tidied when valid; anything else is kept as-is so the check flags it.
  static String _displayContact(String? raw) {
    final text = (raw ?? '').trim();
    return _isValidPhMobile(text) ? _formatPhMobile(_phMobileDigits(text)) : text;
  }

  /// Optional field: empty is fine, otherwise it must be an 11-digit PH mobile number.
  static String? _contactError(String? text) {
    final t = (text ?? '').trim();
    if (t.isEmpty || _isValidPhMobile(t)) return null;
    return 'Enter an 11-digit PH mobile number (09XX XXX XXXX)';
  }

  /// Sector/age mismatches worth a second look (never blocks saving).
  List<String> _sectorAgeWarnings(Set<String> sectors, DateTime? birth) {
    if (birth == null) return const [];
    final age = _ageOn(birth);
    return [
      if (sectors.contains('Youth') && (age < 15 || age > 30)) 'Youth is usually 15–30; this member is $age.',
      if (sectors.contains('Senior Citizen') && age < 60) 'Senior Citizen is usually 60+; this member is $age.',
    ];
  }

  Widget _buildSectorWarnings(List<String> warnings) {
    if (warnings.isEmpty) return const SizedBox.shrink();
    const amber = Color(0xFFB45309);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final w in warnings)
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: amber),
                const SizedBox(width: 6),
                Flexible(child: Text(w, style: GoogleFonts.inter(fontSize: 11.5, color: amber))),
              ],
            ),
        ],
      ),
    );
  }

  Future<bool> _saveMemberRecord() async {
    // Leave any half-typed field so its "still typing" leniency ends and it's checked;
    // the focus change applies asynchronously (it also expands 2-digit years), so wait for it
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return false;
    if (_isHouseholdLeader) {
      final incomplete = [
        for (var i = 0; i < _dependentMembers.length; i++)
          if (_dependentProblems(_dependentMembers[i]).isNotEmpty) i,
      ];
      if (incomplete.isNotEmpty) {
        setState(() {
          for (final i in incomplete) {
            _dependentMembers[i].expanded = true;
          }
        });
        _revealDependent(_dependentMembers[incomplete.first]);
        // Once the reopened cards are built, mark their empty/invalid fields in red too
        WidgetsBinding.instance.addPostFrameCallback((_) => _formKey.currentState?.validate());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Complete household member ${incomplete.map((i) => '#${i + 1}').join(', ')}: '
              '${_dependentProblems(_dependentMembers[incomplete.first]).join(', ')}.'),
        ));
        return false;
      }
    }
    if (_formKey.currentState?.validate() != true) {
      setState(() {}); // refresh field decorations (e.g. red calendar icon) after the check
      return false;
    }

    setState(() => _isSaving = true);
    try {
      final service = ref.read(supabaseServiceProvider);
      final memberId = widget.existing?.id ?? const Uuid().v4();
      final purokId = _resolvedPurokId;

      // Upload first, so a failed upload (e.g. offline) stops the save before anything is written.
      var avatarUrl = widget.existing?.profilePictureUrl;
      if (_avatarBytes != null) {
        avatarUrl = await service.uploadProfilePicture(memberId: memberId, bytes: _avatarBytes!);
      }

      Household? newHousehold;
      if (_createsNewHousehold) {
        // Approximate house location: a random point near the barangay center.
        final center = barangayCenter(_locations, _lgu, _barangay);
        final point = center == null ? null : jitterAround(center);
        newHousehold = await service.createHousehold(Household(
          id: const Uuid().v4(),
          householdName: _generatedHouseholdName,
          lgu: _lgu,
          barangay: _barangay,
          purok: _purok,
          purokId: purokId,
          latitude: point?.latitude,
          longitude: point?.longitude,
          totalMembers: 1 +
              _dependentMembers
                  .where((d) => d.firstNameCtrl.text.trim().isNotEmpty && d.lastNameCtrl.text.trim().isNotEmpty)
                  .length,
          activeMembers: 1,
          status: 'active',
          createdDate: phNow(),
          updatedDate: phNow(),
          createdBy: 'Admin',
        ));
      }

      final targetHouseholdId = newHousehold?.id ??
          _selectedHousehold?.id ??
          widget.existing?.householdId ??
          widget.presetHousehold?.id ??
          '4d46e4ff-77ff-4714-9eb2-d70bc25cc31c';

      final age = _birthDate != null ? _ageOn(_birthDate!) : (widget.existing?.age ?? 30);

      final primaryMember = FamilyMember(
        id: memberId,
        householdId: targetHouseholdId,
        firstname: _firstNameCtrl.text.trim(),
        lastname: _lastNameCtrl.text.trim(),
        middlename: _middleNameCtrl.text.trim().isNotEmpty ? _middleNameCtrl.text.trim() : null,
        contactNumber: _phMobileDigits(_contactCtrl.text).isNotEmpty ? _phMobileDigits(_contactCtrl.text) : null,
        lgu: _lgu,
        barangay: _barangay,
        purok: _purok,
        purokId: purokId,
        sector: _joinSectors(_selectedSectors),
        yearLevel: _selectedSectors.contains('Student') ? _yearLevel : null,
        gender: _gender,
        birthDate: _birthDate,
        membershipDate: _membershipDate,
        age: age,
        isHouseholdLeader: _isHouseholdLeader,
        isCooperativeMember: true,
        isVoter: _isVoter,
        listingStatus: _listingStatus,
        trucareMember: _trucareMember,
        phicMember: _phicMember,
        phicNo: _phicNoCtrl.text.trim().isNotEmpty ? _phicNoCtrl.text.trim() : null,
        profilePictureUrl: avatarUrl,
        createdDate: widget.existing?.createdDate ?? phNow(),
        updatedDate: phNow(),
        createdBy: widget.existing?.createdBy ?? 'Admin',
      );

      // The notifier swallows errors (null / false), so surface them as a failed save
      if (widget.existing == null) {
        final created = await ref.read(memberListNotifierProvider.notifier).addMember(primaryMember);
        if (created == null) throw Exception('the member could not be saved');
        _savedMember = created;
      } else {
        final ok = await ref.read(memberListNotifierProvider.notifier).updateMember(primaryMember);
        if (!ok) throw Exception('the changes could not be saved');
        _savedMember = primaryMember;
      }

      // Save additional dependent rows if entered (only when this member leads the household)
      final List<FamilyMember> dependentsToSave = [];
      for (var d in _isHouseholdLeader ? _dependentMembers : const <DependentMemberData>[]) {
        final fName = d.firstNameCtrl.text.trim();
        final lName = d.lastNameCtrl.text.trim();
        if (fName.isNotEmpty && lName.isNotEmpty) {
          final depAge = d.birthDate != null ? _ageOn(d.birthDate!) : null;
          dependentsToSave.add(FamilyMember(
            id: const Uuid().v4(),
            householdId: targetHouseholdId,
            firstname: fName,
            lastname: lName,
            middlename: d.middleNameCtrl.text.trim().isNotEmpty ? d.middleNameCtrl.text.trim() : null,
            contactNumber: _phMobileDigits(d.contactCtrl.text).isNotEmpty ? _phMobileDigits(d.contactCtrl.text) : null,
            lgu: _lgu,
            barangay: _barangay,
            purok: _purok,
            purokId: purokId,
            sector: _joinSectors(d.sectors),
            yearLevel: d.sectors.contains('Student') ? d.yearLevel : null,
            gender: d.gender,
            birthDate: d.birthDate,
            membershipDate: _membershipDate, // household members share the leader's membership date
            age: depAge,
            isHouseholdLeader: false,
            isCooperativeMember: true,
            isVoter: d.fromVoterRecord, // only when a voter record was picked for this row
            listingStatus: 'TROPA MEMBER',
            trucareMember: d.trucareMember,
            phicMember: d.phicMember,
            phicNo: d.phicMember && d.phicNoCtrl.text.trim().isNotEmpty ? d.phicNoCtrl.text.trim() : null,
            createdDate: phNow(),
            updatedDate: phNow(),
            createdBy: 'Admin',
          ));
        }
      }

      if (dependentsToSave.isNotEmpty) {
        await ref.read(memberListNotifierProvider.notifier).addMembersBulk(dependentsToSave);
      }

      // Link the new household to its leader now that the member row exists
      if (newHousehold != null) {
        await service.updateHousehold(newHousehold.copyWith(householdLeaderId: memberId));
      }

      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving record: $e'), backgroundColor: TropaColors.error),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetFormForAnother() {
    setState(() {
      _currentStep = MemberFormStep.voterSearch;
      _selectedVoter = null;
      _searchResults = [];
      _searchPerformed = false;
      _searchLastNameCtrl.clear();
      _searchFirstNameCtrl.clear();
      _searchMiddleNameCtrl.clear();

      _lastNameCtrl.clear();
      _firstNameCtrl.clear();
      _middleNameCtrl.clear();
      _contactCtrl.clear();
      _phicNoCtrl.clear();
      _birthDate = null;
      _membershipDate = _joiningHousehold ? null : phToday();
      _selectedSectors.clear();
      _selectedSectors.add('General');
      _seniorAutoChecked = false;
      _yearLevel = null;
      _gender = null;
      _showMoreDetails = false;
      _trucareMember = false;
      _phicMember = false;
      _isHouseholdLeader = false;
      _selectedHousehold = widget.presetHousehold;
      _voterSearchDependentIndex = null;
      _possibleMatches = [];
      _isVoter = false;
      _listingStatus = 'TROPA MEMBER';
      _avatarBytes = null;
      _avatarName = null;

      for (var d in _dependentMembers) {
        d.dispose();
      }
      _dependentMembers.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'TROPA Member saved! Returning to voter search for next entry.',
          style: TextStyle(color: TropaColors.onPrimaryOf(context)),
        ),
        backgroundColor: TropaColors.primaryOf(context),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(locationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dlgBg = TropaColors.cardOf(context);
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final borderCol = TropaColors.borderOf(context);
    final cardBg = TropaColors.subtleOf(context);
    final inputFill = TropaColors.subtleOf(context);
    final primaryCol = TropaColors.primaryOf(context);
    final onPrimaryCol = TropaColors.onPrimaryOf(context);

    final screenWidth = MediaQuery.of(context).size.width;
    // Phones get the whole screen; elsewhere the intake form grows on big screens and the
    // summary sidebar only appears when there's room for it
    final compact = TropaBreakpoints.isCompact(screenWidth);
    final dialogWidth = compact
        ? screenWidth
        : _currentStep == MemberFormStep.voterSearch
            ? (screenWidth * 0.92).clamp(740.0, 900.0)
            : (screenWidth * 0.94).clamp(740.0, 1380.0);
    _sidebarVisible = _currentStep == MemberFormStep.memberForm && dialogWidth >= 1080;

    return Dialog(
      backgroundColor: dlgBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(compact ? 0 : 16)),
      insetPadding: compact ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: MediaQuery.of(context).size.height * (compact ? 1 : 0.92),
        ),
        child: SafeArea(
          top: compact,
          bottom: compact,
          left: compact,
          right: compact,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal Top Header
            Container(
              padding: _currentStep == MemberFormStep.voterSearch
                  ? const EdgeInsets.fromLTRB(20, 18, 12, 18)
                  : const EdgeInsets.fromLTRB(28, 20, 20, 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderCol)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.existing == null ? 'Add New TROPA Member' : 'Edit TROPA Member Profile',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textCol,
                          ),
                        ),
                      ),
                      if (!compact && widget.existing == null && _currentStep == MemberFormStep.memberForm) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryCol.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Step 2: Intake Details',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: primaryCol,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: subtextCol, size: 22),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(_savedMember),
                  ),
                ],
              ),
            ),

            // Content changes based on Step
            // Search step hugs its content; intake form fills the available height
            if (_currentStep == MemberFormStep.voterSearch)
              Flexible(
                child: _buildStep1VoterSearch(
                    isDark, cardBg, borderCol, textCol, subtextCol, inputFill, primaryCol, onPrimaryCol),
              )
            else
              Expanded(
                child: _buildStep2MemberForm(
                    isDark, cardBg, borderCol, textCol, subtextCol, inputFill, primaryCol, onPrimaryCol),
              ),
          ],
        ),
        ),
      ),
    );
  }

  // =========================================================================
  // STEP 1: Find Voter Record Screen (Screenshot 2)
  // =========================================================================
  Widget _buildStep1VoterSearch(
    bool isDark,
    Color cardBg,
    Color borderCol,
    Color textCol,
    Color subtextCol,
    Color inputFill,
    Color primaryCol,
    Color onPrimaryCol,
  ) {
    final fieldText = GoogleFonts.inter(fontSize: 13, color: textCol);
    final fieldFill = TropaColors.fieldFillOf(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: primaryCol, size: 18),
              const SizedBox(width: 10),
              Text(
                _voterSearchDependentIndex != null
                    ? 'Find Voter Record — Household Member #${_voterSearchDependentIndex! + 1}'
                    : 'Find Voter Record',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textCol,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _voterSearchDependentIndex != null
                ? 'Select a voter to fill this household member, or go back to the form.'
                : 'Filter by location and search by name, or skip to fill the form manually.',
            style: GoogleFonts.inter(fontSize: 11.5, color: subtextCol),
          ),
          const SizedBox(height: 22),

          // Row 1: LGU and Barangay Filters
          ResponsiveFieldRow(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _labeledField(
                  'LGU',
                  subtextCol,
                  DropdownButtonFormField<String>(
                    value:
                        _withCurrent(['All LGUs', ..._lgus], _searchLgu).contains(_searchLgu) ? _searchLgu : 'All LGUs',
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down, size: 20, color: textCol),
                    decoration: _searchBoxDecoration(null, borderCol, fieldFill, primaryCol, subtextCol),
                    dropdownColor: TropaColors.cardOf(context),
                    style: fieldText,
                    items: _withCurrent(['All LGUs', ..._lgus], _searchLgu)
                        .map((l) => DropdownMenuItem(
                            value: l, child: Text(l, style: fieldText, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _searchLgu = v;
                          // Barangay list depends on the LGU
                          if (!_barangaysFor(v).contains(_searchBarangay)) _searchBarangay = 'All Barangays';
                        });
                        _executeVoterSearch();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _labeledField(
                  'Barangay',
                  subtextCol,
                  DropdownButtonFormField<String>(
                    value: _withCurrent(['All Barangays', ..._barangaysFor(_searchLgu)], _searchBarangay)
                            .contains(_searchBarangay)
                        ? _searchBarangay
                        : 'All Barangays',
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down, size: 20, color: textCol),
                    decoration: _searchBoxDecoration(null, borderCol, fieldFill, primaryCol, subtextCol),
                    dropdownColor: TropaColors.cardOf(context),
                    style: fieldText,
                    items: _withCurrent(['All Barangays', ..._barangaysFor(_searchLgu)], _searchBarangay)
                        .map((b) => DropdownMenuItem(
                            value: b, child: Text(b, style: fieldText, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _searchBarangay = v);
                        _executeVoterSearch();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: Last Name, First Name, Middle Name
          ResponsiveFieldRow(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _labeledField(
                  'Last Name',
                  subtextCol,
                  TextField(
                    inputFormatters: const [UpperCaseFormatter()],
                    textCapitalization: TextCapitalization.characters,
                    controller: _searchLastNameCtrl,
                    autofocus: true,
                    style: fieldText,
                    decoration: _searchBoxDecoration(
                        'Search last name...', borderCol, fieldFill, primaryCol, subtextCol,
                        withIcon: true),
                    onChanged: (_) => _onSearchFieldChanged(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _labeledField(
                  'First Name',
                  subtextCol,
                  TextField(
                    inputFormatters: const [UpperCaseFormatter()],
                    textCapitalization: TextCapitalization.characters,
                    controller: _searchFirstNameCtrl,
                    style: fieldText,
                    decoration: _searchBoxDecoration(
                        'Search first name...', borderCol, fieldFill, primaryCol, subtextCol,
                        withIcon: true),
                    onChanged: (_) => _onSearchFieldChanged(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _labeledField(
                  'Middle Name',
                  subtextCol,
                  TextField(
                    inputFormatters: const [UpperCaseFormatter()],
                    textCapitalization: TextCapitalization.characters,
                    controller: _searchMiddleNameCtrl,
                    style: fieldText,
                    decoration: _searchBoxDecoration(
                        'Search middle name...', borderCol, fieldFill, primaryCol, subtextCol,
                        withIcon: true),
                    onChanged: (_) => _onSearchFieldChanged(),
                  ),
                ),
              ),
            ],
          ),

          if (_isSearching) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(color: primaryCol, minHeight: 2),
          ],

          // Results Table — only shown once a search has been made
          if (_searchPerformed && !_isSearching || _searchResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: TropaColors.cardOf(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderCol),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  children: [
                    // Table Header (phones show each result as a card instead)
                    if (!context.isCompactScreen)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: TropaColors.chipOf(context),
                        border: Border(bottom: BorderSide(color: borderCol)),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 4, child: _tableHeader('LAST NAME', subtextCol)),
                          Expanded(flex: 6, child: _tableHeader('FIRST NAME', subtextCol)),
                          Expanded(flex: 4, child: _tableHeader('MIDDLE NAME', subtextCol)),
                          Expanded(flex: 4, child: _tableHeader('LGU', subtextCol)),
                          Expanded(flex: 4, child: _tableHeader('BRGY', subtextCol)),
                          Expanded(flex: 4, child: _tableHeader('STATUS', subtextCol)),
                          Expanded(flex: 3, child: Center(child: _tableHeader('ACTION', subtextCol))),
                        ],
                      ),
                    ),

                    // Table Body
                    if (_searchResults.isNotEmpty)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: borderCol),
                        itemBuilder: (context, idx) {
                          final v = _searchResults[idx];
                          final cell = GoogleFonts.inter(fontSize: 12, color: textCol);
                          final mutedCell = GoogleFonts.inter(fontSize: 12, color: subtextCol);
                          if (context.isCompactScreen) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${v.lastName}, ${v.firstName} ${v.middleName ?? ''}'.trim(),
                                            style: cell.copyWith(fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 2),
                                        Text('${v.barangay}, ${v.lgu} · ${v.status.toUpperCase()}', style: mutedCell),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _voterSelectButton(v, primaryCol),
                                ],
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(v.lastName, style: cell.copyWith(fontWeight: FontWeight.w700)),
                                ),
                                Expanded(flex: 6, child: Text(v.firstName, style: cell)),
                                Expanded(flex: 4, child: Text(v.middleName ?? '-', style: cell)),
                                Expanded(flex: 4, child: Text(v.lgu, style: mutedCell)),
                                Expanded(flex: 4, child: Text(v.barangay, style: mutedCell)),
                                Expanded(
                                  flex: 4,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: TropaColors.chipOf(context),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        v.status.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                          color: textCol,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Center(child: _voterSelectButton(v, primaryCol)),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_search_outlined, size: 32, color: subtextCol),
                              const SizedBox(height: 8),
                              Text(
                                'No registered voter records found.',
                                style: GoogleFonts.inter(fontSize: 12, color: subtextCol),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Bottom Skip Link
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: _skipToManualForm,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  _voterSearchDependentIndex != null ? 'Back to the form' : 'Skip — fill the form manually',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    decorationColor: subtextCol,
                    color: subtextCol,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labeledField(String label, Color subtextCol, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: subtextCol),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  InputDecoration _searchBoxDecoration(String? hint, Color borderCol, Color fillCol, Color primaryCol, Color subtextCol,
      {bool withIcon = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 13, color: subtextCol.withValues(alpha: 0.75)),
      prefixIcon: withIcon ? Icon(Icons.search, size: 18, color: subtextCol) : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 20),
      isDense: true,
      filled: true,
      fillColor: fillCol,
      contentPadding: EdgeInsets.fromLTRB(withIcon ? 0 : 14, 13, 12, 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderCol),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderCol),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryCol, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: TropaColors.errorOf(context), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: TropaColors.errorOf(context), width: 2),
      ),
      errorStyle: GoogleFonts.inter(fontSize: 11, color: TropaColors.errorOf(context)),
    );
  }

  // =========================================================================
  // STEP 2: Intake Form Screen (Screenshots 3 & 4)
  // =========================================================================
  Widget _buildStep2MemberForm(
    bool isDark,
    Color cardBg,
    Color borderCol,
    Color textCol,
    Color subtextCol,
    Color inputFill,
    Color primaryCol,
    Color onPrimaryCol,
  ) {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  // Remembers the scroll offset while the form is swapped out for the voter search
                  key: const PageStorageKey('member-intake-form'),
                  padding: const EdgeInsets.fromLTRB(28, 14, 28, 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button or Voter Found Banner
                        if (_selectedVoter != null) ...[
                          _buildVoterFoundBanner(isDark, borderCol, textCol, subtextCol, primaryCol),
                          const SizedBox(height: 28),
                        ] else if (_possibleMatches.isNotEmpty) ...[
                          _buildPossibleMatchBanner(
                            isDark,
                            matches: _possibleMatches,
                            nameCtrls: [_firstNameCtrl, _middleNameCtrl, _lastNameCtrl],
                            onReview: _reviewPossibleMatches,
                            onDismiss: () => setState(() => _possibleMatches = []),
                          ),
                          const SizedBox(height: 28),
                        ] else if (widget.existing == null) ...[
                          InkWell(
                            onTap: _backToSearch,
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_back, size: 16, color: primaryCol),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Back to Voter Search',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: primaryCol,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Section 1: Personal Information (photo beside the fields)
                        _buildSectionHeader('Personal Information', textCol),
                        const SizedBox(height: 18),
                        ResponsiveFieldRow(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPhotoPicker(isDark, borderCol, textCol, subtextCol, primaryCol),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Row 1: Last Name, First Name, Middle Name
                                  ResponsiveFieldRow(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _lastNameCtrl,
                                          label: 'Last Name *',
                                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                          textCol: textCol,
                                          borderCol: borderCol,
                                          fillCol: inputFill,
                                          primaryCol: primaryCol,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _firstNameCtrl,
                                          label: 'First Name *',
                                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                          textCol: textCol,
                                          borderCol: borderCol,
                                          fillCol: inputFill,
                                          primaryCol: primaryCol,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _middleNameCtrl,
                                          label: 'Middle Name',
                                          textCol: textCol,
                                          borderCol: borderCol,
                                          fillCol: inputFill,
                                          primaryCol: primaryCol,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // Row 2: Birthday, Membership Date, Contact Number
                                  ResponsiveFieldRow(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildDatePickerField(
                                          label: 'Birthday *',
                                          date: _birthDate,
                                          hint: 'mm/dd/yyyy',
                                          isBirthDate: true,
                                          onDateSelected: (d) => setState(() {
                                            _birthDate = d;
                                            _applySeniorRule();
                                          }),
                                          onCleared: () => setState(() => _birthDate = null),
                                          textCol: textCol,
                                          borderCol: borderCol,
                                          fillCol: inputFill,
                                          primaryCol: primaryCol,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: _buildDatePickerField(
                                          label: 'Membership Date *',
                                          date: _membershipDate,
                                          hint: 'mm/dd/yyyy',
                                          onDateSelected: (d) => setState(() => _membershipDate = d),
                                          onCleared: () => setState(() => _membershipDate = null),
                                          textCol: textCol,
                                          borderCol: borderCol,
                                          fillCol: inputFill,
                                          primaryCol: primaryCol,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _contactCtrl,
                                          label: 'Contact Number',
                                          upperCase: false,
                                          hint: '0917 123 4567',
                                          inputFormatters: [_PhMobileFormatter()],
                                          keyboardType: TextInputType.phone,
                                          validator: _contactError,
                                          textCol: textCol,
                                          borderCol: borderCol,
                                          fillCol: inputFill,
                                          primaryCol: primaryCol,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Gender (required)
                                  _buildGenderField(
                                    key: const ValueKey('gender-main'),
                                    value: _gender,
                                    onChanged: (g) => setState(() => _gender = g),
                                    textCol: textCol,
                                    borderCol: borderCol,
                                    primaryCol: primaryCol,
                                    subtextCol: subtextCol,
                                  ),
                                  const SizedBox(height: 16),

                                  // Row 3: Sector chips
                                  Text('Sector *',
                                      style: GoogleFonts.inter(
                                          fontSize: 11.5, fontWeight: FontWeight.w500, color: subtextCol)),
                                  const SizedBox(height: 8),
                                  _buildSectorChips(
                                    selected: _selectedSectors,
                                    onToggle: (sector, selected) => _setSector(sector, selected),
                                    textCol: textCol,
                                    borderCol: borderCol,
                                    primaryCol: primaryCol,
                                  ),
                                  _buildSectorWarnings(_sectorAgeWarnings(_selectedSectors, _birthDate)),
                                  const SizedBox(height: 14),

                                  // Year Level (students only), in a third-width column like the fields above
                                  if (_selectedSectors.contains('Student')) ...[
                                    ResponsiveFieldRow(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildYearLevelField(
                                            value: _yearLevel,
                                            onChanged: (v) => setState(() => _yearLevel = v),
                                            isDark: isDark,
                                            textCol: textCol,
                                            borderCol: borderCol,
                                            primaryCol: primaryCol,
                                            subtextCol: subtextCol,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        const Expanded(flex: 2, child: SizedBox.shrink()),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                  ],

                                  // Optional details: TRU Care, PhilHealth
                                  if (_moreDetailsOpen) ...[
                                    Wrap(
                                      spacing: 24,
                                      runSpacing: 10,
                                      children: [
                                        _buildCheckbox(
                                          label: 'TRU Care Member',
                                          value: _trucareMember,
                                          onChanged: (v) => setState(() => _trucareMember = v ?? false),
                                          textCol: textCol,
                                          primaryCol: primaryCol,
                                          onPrimaryCol: onPrimaryCol,
                                        ),
                                        _buildCheckbox(
                                          label: 'PhilHealth Member',
                                          value: _phicMember,
                                          onChanged: (v) => setState(() => _phicMember = v ?? false),
                                          textCol: textCol,
                                          primaryCol: primaryCol,
                                          onPrimaryCol: onPrimaryCol,
                                        ),
                                      ],
                                    ),
                                    if (_phicMember) ...[
                                      const SizedBox(height: 12),
                                      ResponsiveFieldRow(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: _buildTextField(
                                              controller: _phicNoCtrl,
                                              label: 'PhilHealth (PHIC) No.',
                                              upperCase: false,
                                              hint: '12-digit identification number',
                                              textCol: textCol,
                                              borderCol: borderCol,
                                              fillCol: inputFill,
                                              primaryCol: primaryCol,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          const Expanded(flex: 2, child: SizedBox.shrink()),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                  ],
                                  _buildMoreDetailsLink(
                                    open: _moreDetailsOpen,
                                    // Keep it open while any optional field holds a value
                                    canClose: !_hasMoreDetails,
                                    onTap: () => setState(() => _showMoreDetails = !_moreDetailsOpen),
                                    primaryCol: primaryCol,
                                    subtextCol: subtextCol,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Section 2: Household & Location (leader choice first: it decides the household)
                        _buildSectionHeader('Household & Location', textCol),
                        const SizedBox(height: 14),
                        if (_joiningHousehold)
                          // Joining an existing household: shown but can't be ticked
                          Row(
                            children: [
                              Icon(Icons.check_box_outline_blank, size: 22, color: subtextCol.withValues(alpha: 0.45)),
                              const SizedBox(width: 10),
                              Text('Household Leader',
                                  style: GoogleFonts.inter(fontSize: 13, color: subtextCol.withValues(alpha: 0.7))),
                            ],
                          )
                        else
                          _buildCheckbox(
                            label: 'Household Leader',
                            value: _isHouseholdLeader,
                            onChanged: (v) => setState(() => _isHouseholdLeader = v ?? false),
                            textCol: textCol,
                            primaryCol: primaryCol,
                            onPrimaryCol: onPrimaryCol,
                          ),
                        Padding(
                          padding: const EdgeInsets.only(left: 32, top: 2),
                          child: Text(
                            _joiningHousehold
                                ? 'Adding to ${widget.presetHousehold!.householdName}; this member joins as a household member.'
                                : _isHouseholdLeader
                                    ? 'A new household is created for this member, and you can add the rest of the household below.'
                                    : 'Tick if this member heads their household.',
                            style: GoogleFonts.inter(fontSize: 11.5, color: subtextCol),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Row 1: Household search dropdown & LGU
                        ResponsiveFieldRow(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _labeledField(
                                'Household',
                                subtextCol,
                                _buildHouseholdNameBox(isDark, borderCol, textCol, subtextCol),
                              ),
                            ),
                            const SizedBox(width: 28),
                            Expanded(
                              child: _labeledField(
                                  'LGU *',
                                  subtextCol,
                                  DropdownButtonFormField<String>(
                                    value: _lgu.isEmpty ? null : _lgu,
                                    isExpanded: true,
                                    icon: Icon(Icons.keyboard_arrow_down, size: 20, color: textCol),
                                    decoration:
                                        _searchBoxDecoration(null, borderCol, _fieldFill, primaryCol, subtextCol),
                                    dropdownColor: TropaColors.cardOf(context),
                                    hint: Text('Select LGU', style: GoogleFonts.inter(fontSize: 13, color: textCol)),
                                    disabledHint: _lockedValue(_lgu, textCol),
                                    items: _withCurrent(_lgus, _lgu).map((l) {
                                      return DropdownMenuItem(
                                        value: l,
                                        child: Text(l,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(fontSize: 13, color: textCol)),
                                      );
                                    }).toList(),
                                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                    onChanged: _joiningHousehold
                                        ? null
                                        : (v) {
                                            if (v != null) {
                                              setState(() {
                                                _lgu = v;
                                                // Barangay list depends on the LGU
                                                if (!_barangaysFor(v).contains(_barangay)) _barangay = '';
                                                _purok = '';
                                                _purokId = null;
                                              });
                                            }
                                          },
                                  )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Row 2: Barangay & Purok
                        ResponsiveFieldRow(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _labeledField(
                                  'Barangay *',
                                  subtextCol,
                                  DropdownButtonFormField<String>(
                                    // Keyed by LGU so the field resets cleanly when the LGU changes
                                    key: ValueKey('barangay-$_lgu'),
                                    value: _barangay.isEmpty ? null : _barangay,
                                    isExpanded: true,
                                    icon: Icon(Icons.keyboard_arrow_down, size: 20, color: textCol),
                                    decoration:
                                        _searchBoxDecoration(null, borderCol, _fieldFill, primaryCol, subtextCol),
                                    dropdownColor: TropaColors.cardOf(context),
                                    hint: Text(
                                      _lgu.isEmpty ? 'Select LGU First' : 'Select Barangay',
                                      style: GoogleFonts.inter(fontSize: 13, color: textCol),
                                    ),
                                    disabledHint: _joiningHousehold ? _lockedValue(_barangay, textCol) : null,
                                    items: _lgu.isEmpty
                                        ? const []
                                        : _withCurrent(_barangaysFor(_lgu), _barangay).map((b) {
                                            return DropdownMenuItem(
                                              value: b,
                                              child: Text(b,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.inter(fontSize: 13, color: textCol)),
                                            );
                                          }).toList(),
                                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                    onChanged: _joiningHousehold
                                        ? null
                                        : (v) {
                                            if (v != null && v != _barangay) {
                                              setState(() {
                                                _barangay = v;
                                                _purok = '';
                                                _purokId = null;
                                              });
                                            }
                                          },
                                  )),
                            ),
                            const SizedBox(width: 28),
                            Expanded(
                              child: _labeledField('Purok *', subtextCol,
                                  _buildPurokDropdown(isDark, borderCol, textCol, primaryCol, subtextCol)),
                            ),
                          ],
                        ),
                        if (_joiningHousehold) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.lock_outline, size: 14, color: subtextCol),
                              const SizedBox(width: 6),
                              Text('Location follows the household.',
                                  style: GoogleFonts.inter(fontSize: 11.5, color: subtextCol)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Section 3: Status & Qualifications (status shown as a badge)
                        _buildSectionHeader(
                          'Status & Qualifications',
                          textCol,
                          trailing: [
                            _buildBadge(
                              (_listingStatus.toUpperCase() == 'MEMBER' || _listingStatus.toUpperCase() == 'COOP')
                                  ? 'TROPA MEMBER'
                                  : _listingStatus,
                              primaryCol,
                            ),
                            if (_selectedVoter != null)
                              Text('From voter record', style: GoogleFonts.inter(fontSize: 11, color: subtextCol)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Read-only: follows whether a record from the voters table was selected
                        Row(
                          children: [
                            Icon(
                              _isVoter ? Icons.check_box : Icons.check_box_outline_blank,
                              size: 22,
                              color: _isVoter ? primaryCol : subtextCol.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 10),
                            Text('Registered Voter', style: GoogleFonts.inter(fontSize: 13, color: textCol)),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 32, top: 2),
                          child: Text(
                            _isVoter
                                ? (_selectedVoter != null
                                    ? 'Found in the voters table.'
                                    : 'Saved as a registered voter.')
                                : 'Ticked automatically when a voter record is selected.',
                            style: GoogleFonts.inter(fontSize: 11.5, color: subtextCol),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Section 4: Household Members / Dependents
                        // (only household leaders can add the rest of their household)
                        if (_isHouseholdLeader) ...[
                          _buildHouseholdMembersSection(
                              isDark, cardBg, borderCol, textCol, subtextCol, inputFill, primaryCol, onPrimaryCol),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (_sidebarVisible) _buildSummarySidebar(isDark, borderCol, textCol, subtextCol, primaryCol),
            ],
          ),
        ),

        // Modal Bottom Actions
        Container(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: borderCol)),
          ),
          // Wraps onto two lines when the three buttons don't fit (phones)
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 10,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  side: BorderSide(color: borderCol),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.of(context).pop(_savedMember),
                child: Text('Cancel', style: GoogleFonts.inter(color: textCol, fontWeight: FontWeight.w500)),
              ),
              if (widget.existing == null)
                // Secondary action: tinted version of the theme colour so it follows the theme
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryCol,
                    backgroundColor: primaryCol.withValues(alpha: 0.08),
                    side: BorderSide(color: primaryCol.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save & Add Another'),
                  onPressed: _isSaving
                      ? null
                      : () async {
                          final success = await _saveMemberRecord();
                          if (success) {
                            _resetFormForAnother();
                          }
                        },
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryCol,
                  foregroundColor: onPrimaryCol,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                icon: _isSaving
                    ? SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(color: onPrimaryCol, strokeWidth: 2))
                    : const Icon(Icons.save, size: 18),
                label: Text(
                  widget.existing == null ? 'Save TROPA Member' : 'Update Profile',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                onPressed: _isSaving
                    ? null
                    : () async {
                        final nav = Navigator.of(context);
                        final success = await _saveMemberRecord();
                        if (success && mounted) {
                          nav.pop(_savedMember);
                        }
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // Helper UI Elements
  // ==========================================

  /// Read-only household name: the generated "… FAMILY" name for a new leader,
  /// otherwise the household this member already belongs to (blank if none).
  Widget _buildHouseholdNameBox(bool isDark, Color borderCol, Color textCol, Color subtextCol) {
    final String name;
    if (widget.presetHousehold != null) {
      name = widget.presetHousehold!.householdName;
    } else if (widget.existing != null) {
      name = _selectedHousehold?.householdName ?? '';
    } else {
      name = _isHouseholdLeader ? _generatedHouseholdName : '';
    }
    final active = name.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: active ? _fieldFill : TropaColors.subtleOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderCol),
      ),
      child: Text(
        active ? name : 'Check "Household Leader" to create a household',
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(fontSize: 13, color: active ? textCol : subtextCol.withValues(alpha: 0.75)),
      ),
    );
  }

  /// Purok options come from the `puroks` table for the selected LGU + barangay.
  /// Shows a locked dropdown's current value (a disabled dropdown otherwise only shows its hint).
  Widget _lockedValue(String value, Color textCol) => Text(value.isEmpty ? '—' : value,
      overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, color: textCol.withValues(alpha: 0.7)));

  Widget _buildPurokDropdown(bool isDark, Color borderCol, Color textCol, Color primaryCol, Color subtextCol) {
    final locationId = _locationId;
    final puroksAsync = locationId == null ? null : ref.watch(puroksProvider(locationId));
    final puroks = puroksAsync?.valueOrNull ?? const <({String id, String name})>[];
    final names = _withCurrent(puroks.map((p) => p.name).toList(), _purok);

    final String hint;
    if (_barangay.isEmpty) {
      hint = 'Select Barangay First';
    } else if (puroksAsync == null || puroksAsync.isLoading) {
      hint = locationId == null ? 'No puroks listed' : 'Loading puroks…';
    } else if (puroks.isEmpty) {
      hint = 'No puroks listed';
    } else {
      hint = 'Select Purok';
    }

    return DropdownButtonFormField<String>(
      // Rebuilt per location so a stale selection never leaks across barangays
      key: ValueKey('purok-${locationId ?? _barangay}'),
      value: _purok.isEmpty ? null : _purok,
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down, size: 20, color: textCol),
      decoration: _searchBoxDecoration(null, borderCol, _fieldFill, primaryCol, subtextCol),
      dropdownColor: TropaColors.cardOf(context),
      menuMaxHeight: 360,
      hint: Text(hint, style: GoogleFonts.inter(fontSize: 13, color: textCol)),
      disabledHint: _joiningHousehold ? _lockedValue(_purok, textCol) : null,
      items: _barangay.isEmpty
          ? const []
          : names
              .map((n) => DropdownMenuItem(
                    value: n,
                    child: Text(n,
                        overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, color: textCol)),
                  ))
              .toList(),
      // Only required when this barangay actually has puroks listed
      validator: (v) => (puroks.isNotEmpty && (v == null || v.isEmpty)) ? 'Required' : null,
      onChanged: _joiningHousehold
          ? null
          : (v) {
              if (v == null) return;
              setState(() {
                _purok = v;
                _purokId = null;
                for (final p in puroks) {
                  if (p.name == v) _purokId = p.id;
                }
              });
            },
    );
  }

  /// Year Level dropdown shown for Students (required while visible).
  Widget _buildYearLevelField({
    required String? value,
    required ValueChanged<String> onChanged,
    required bool isDark,
    required Color textCol,
    required Color borderCol,
    required Color primaryCol,
    required Color subtextCol,
  }) {
    return _labeledField(
      'Year Level *',
      subtextCol,
      DropdownButtonFormField<String>(
        value: _yearLevels.contains(value) ? value : null,
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down, size: 20, color: textCol),
        decoration: _searchBoxDecoration(null, borderCol, _fieldFill, primaryCol, subtextCol),
        dropdownColor: TropaColors.cardOf(context),
        hint: Text('Select Year Level', style: GoogleFonts.inter(fontSize: 13, color: textCol)),
        items: _yearLevels
            .map((y) =>
                DropdownMenuItem(value: y, child: Text(y, style: GoogleFonts.inter(fontSize: 13, color: textCol))))
            .toList(),
        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  Widget _buildBadge(String text, Color primaryCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(color: primaryCol.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(text,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: primaryCol)),
    );
  }

  Widget _buildSectionHeader(String title, Color textCol, {List<Widget> trailing = const []}) {
    final borderCol = TropaColors.borderOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: textCol,
              ),
            ),
            ...trailing,
          ],
        ),
        const SizedBox(height: 10),
        Divider(height: 1, thickness: 1, color: borderCol),
      ],
    );
  }

  Widget _voterSelectButton(VoterSearchResult v, Color primaryCol) => OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryCol,
          backgroundColor: primaryCol.withValues(alpha: 0.08),
          side: BorderSide(color: primaryCol.withValues(alpha: 0.25)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: const Icon(Icons.person_add_alt_outlined, size: 14),
        label: Text('Select', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600)),
        onPressed: () => _selectVoterAndProceed(v),
      );

  Widget _tableHeader(String label, Color subtextCol) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: subtextCol,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildPossibleMatchBanner(
    bool isDark, {
    required List<VoterSearchResult> matches,
    required List<TextEditingController> nameCtrls,
    required VoidCallback onReview,
    required VoidCallback onDismiss,
  }) {
    const amber = Color(0xFFD97706);
    final titleCol = isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);
    final bodyCol = isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309);
    final count = matches.length;
    final typedName = nameCtrls.map((c) => c.text.trim().toUpperCase()).where((n) => n.isNotEmpty).join(' ');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: isDark ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: amber.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.info_outline, size: 18, color: amber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Possible voter match found!',
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: titleCol),
                ),
                const SizedBox(height: 3),
                Text(
                  'We found $count record${count == 1 ? '' : 's'} matching "$typedName".',
                  style: GoogleFonts.inter(fontSize: 12, color: bodyCol),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: amber,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: onReview,
            child: Text('Review Matches', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: amber),
            tooltip: 'Dismiss',
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }

  Widget _buildVoterFoundBanner(bool isDark, Color borderCol, Color textCol, Color subtextCol, Color primaryCol) {
    final voter = _selectedVoter!;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: primaryCol.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryCol.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.how_to_reg_outlined, color: primaryCol, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voter found: ${voter.lastName}, ${voter.firstName} ${voter.middleName ?? ''}'.trim(),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: primaryCol,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Details pre-filled — review and complete remaining fields.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: primaryCol.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: primaryCol),
            tooltip: 'Clear and re-search voter',
            onPressed: () {
              setState(() {
                _selectedVoter = null;
                if (widget.existing == null) _isVoter = false;
                _currentStep = MemberFormStep.voterSearch;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHouseholdMembersSection(
    bool isDark,
    Color cardBg,
    Color borderCol,
    Color textCol,
    Color subtextCol,
    Color inputFill,
    Color primaryCol,
    Color onPrimaryCol,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_add_outlined, color: primaryCol, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Household Members',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: textCol),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_dependentMembers.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text('(${_dependentMembers.length})', style: GoogleFonts.inter(fontSize: 12, color: subtextCol)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'They share this household\'s location. Click a folded row to edit it.',
            style: GoogleFonts.inter(fontSize: 11.5, color: subtextCol),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < _dependentMembers.length; i++) ...[
            _dependentMembers[i].expanded
                ? _buildDependentMemberCard(
                    i, isDark, borderCol, textCol, subtextCol, inputFill, primaryCol, onPrimaryCol)
                : _buildDependentSummaryRow(i, isDark, borderCol, textCol, subtextCol, primaryCol),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryCol,
              backgroundColor: primaryCol.withValues(alpha: 0.08),
              side: BorderSide(color: primaryCol.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Household Member', style: TextStyle(fontWeight: FontWeight.w600)),
            onPressed: _addDependentRow,
          ),
        ],
      ),
    );
  }

  String _dependentDisplayName(DependentMemberData d) {
    final last = d.lastNameCtrl.text.trim().toUpperCase();
    final given = [d.firstNameCtrl.text, d.middleNameCtrl.text]
        .map((n) => n.trim().toUpperCase())
        .where((n) => n.isNotEmpty)
        .join(' ');
    if (last.isEmpty && given.isEmpty) return 'New household member';
    return [last, given].where((n) => n.isNotEmpty).join(', ');
  }

  /// Folded household member: one line with name, age, sectors and year level.
  Widget _buildDependentSummaryRow(
      int index, bool isDark, Color borderCol, Color textCol, Color subtextCol, Color primaryCol) {
    final dep = _dependentMembers[index];
    final problems = _dependentProblems(dep);
    final meta = [
      dep.birthDate != null ? '${_ageOn(dep.birthDate!)} yrs' : 'no birthday',
      if (dep.gender != null) dep.gender!,
      _joinSectors(dep.sectors),
      if (dep.sectors.contains('Student') && dep.yearLevel != null) dep.yearLevel!,
      if (_sectorAgeWarnings(dep.sectors, dep.birthDate).isNotEmpty) 'check sectors',
    ].join(' · ');
    const warn = Color(0xFFD97706);
    void open() => setState(() {
          for (final d in _dependentMembers) {
            d.expanded = false;
          }
          dep.expanded = true;
        });

    return Material(
      key: dep.cardKey,
      color: TropaColors.cardOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: problems.isNotEmpty ? warn.withValues(alpha: 0.6) : borderCol),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
          child: Row(
            children: [
              _memberTag('#${index + 1}', primaryCol),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  _dependentDisplayName(dep),
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textCol),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  problems.isNotEmpty ? 'Missing ${problems.join(', ')}' : meta,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, color: problems.isNotEmpty ? warn : subtextCol),
                ),
              ),
              if (dep.possibleMatches.isNotEmpty)
                Tooltip(
                  message: 'Possible voter match: open to review',
                  child: Icon(Icons.info_outline, size: 18, color: warn),
                ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: subtextCol),
                tooltip: 'Edit',
                onPressed: open,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 18, color: subtextCol),
                tooltip: 'Remove',
                onPressed: () => _removeDependentRow(index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _memberTag(String text, Color primaryCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: primaryCol.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TropaText.badge(primaryCol)),
    );
  }

  Widget _buildDependentMemberCard(
    int index,
    bool isDark,
    Color borderCol,
    Color textCol,
    Color subtextCol,
    Color inputFill,
    Color primaryCol,
    Color onPrimaryCol,
  ) {
    final dep = _dependentMembers[index];
    final hasMore = dep.trucareMember || dep.phicMember;
    final moreOpen = dep.showMore || hasMore;

    return Container(
      key: dep.cardKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TropaColors.cardOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryCol.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _memberTag('TROPA MEMBER #${index + 1}', primaryCol),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryCol,
                      side: BorderSide(color: primaryCol.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.search, size: 14),
                    label: const Text('Search Voter', style: TextStyle(fontSize: 11)),
                    onPressed: () => _searchVoterForDependent(index),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    style: TextButton.styleFrom(
                        foregroundColor: primaryCol, padding: const EdgeInsets.symmetric(horizontal: 10)),
                    onPressed: () => setState(() => dep.expanded = false),
                    child: const Text('Done', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: subtextCol),
                    tooltip: 'Remove',
                    onPressed: () => _removeDependentRow(index),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (dep.possibleMatches.isNotEmpty) ...[
            _buildPossibleMatchBanner(
              isDark,
              matches: dep.possibleMatches,
              nameCtrls: [dep.firstNameCtrl, dep.middleNameCtrl, dep.lastNameCtrl],
              onReview: () => _reviewDependentMatches(dep),
              onDismiss: () => setState(() => dep.possibleMatches = []),
            ),
            const SizedBox(height: 12),
          ],

          // Row 1: Last Name, First Name, Middle Name, Birthday
          ResponsiveFieldRow(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  controller: dep.lastNameCtrl,
                  label: 'Last Name *',
                  textCol: textCol,
                  borderCol: borderCol,
                  fillCol: inputFill,
                  primaryCol: primaryCol,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  controller: dep.firstNameCtrl,
                  label: 'First Name *',
                  textCol: textCol,
                  borderCol: borderCol,
                  fillCol: inputFill,
                  primaryCol: primaryCol,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  controller: dep.middleNameCtrl,
                  label: 'Middle Name',
                  textCol: textCol,
                  borderCol: borderCol,
                  fillCol: inputFill,
                  primaryCol: primaryCol,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDatePickerField(
                  label: 'Birthday *',
                  date: dep.birthDate,
                  hint: 'mm/dd/yyyy',
                  isBirthDate: true,
                  onRangeError: (bad) => setState(() => dep.birthdayInvalid = bad),
                  onDateSelected: (d) => setState(() {
                    dep.birthDate = d;
                    _applyDependentSeniorRule(dep);
                  }),
                  onCleared: () => setState(() => dep.birthDate = null),
                  textCol: textCol,
                  borderCol: borderCol,
                  fillCol: inputFill,
                  primaryCol: primaryCol,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: Contact No., Gender (membership date is the leader's, set on save)
          ResponsiveFieldRow(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  controller: dep.contactCtrl,
                  label: 'Contact No.',
                  upperCase: false,
                  hint: '0917 123 4567',
                  inputFormatters: [_PhMobileFormatter()],
                  keyboardType: TextInputType.phone,
                  validator: _contactError,
                  textCol: textCol,
                  borderCol: borderCol,
                  fillCol: inputFill,
                  primaryCol: primaryCol,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: _buildGenderField(
                  // Keyed per row so each card keeps its own field state
                  key: ValueKey('gender-${identityHashCode(dep)}'),
                  value: dep.gender,
                  onChanged: (g) => setState(() => dep.gender = g),
                  textCol: textCol,
                  borderCol: borderCol,
                  primaryCol: primaryCol,
                  subtextCol: subtextCol,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Sector chips (more than one can apply, e.g. Student + PWD)
          Text('Sector', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: subtextCol)),
          const SizedBox(height: 8),
          _buildSectorChips(
            selected: dep.sectors,
            onToggle: (sector, selected) => _setDependentSector(dep, sector, selected),
            textCol: textCol,
            borderCol: borderCol,
            primaryCol: primaryCol,
          ),
          _buildSectorWarnings(_sectorAgeWarnings(dep.sectors, dep.birthDate)),
          const SizedBox(height: 14),

          // Row 3 (only when needed): Year Level (students), PHIC No.
          if (dep.sectors.contains('Student') || (moreOpen && dep.phicMember)) ...[
            const SizedBox(height: 14),
            ResponsiveFieldRow(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: dep.sectors.contains('Student')
                      ? _buildYearLevelField(
                          value: dep.yearLevel,
                          onChanged: (v) => setState(() => dep.yearLevel = v),
                          isDark: isDark,
                          textCol: textCol,
                          borderCol: borderCol,
                          primaryCol: primaryCol,
                          subtextCol: subtextCol,
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: moreOpen && dep.phicMember
                      ? _buildTextField(
                          controller: dep.phicNoCtrl,
                          label: 'PhilHealth (PHIC) No.',
                          upperCase: false,
                          hint: '12-digit number',
                          textCol: textCol,
                          borderCol: borderCol,
                          fillCol: inputFill,
                          primaryCol: primaryCol,
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 10),
                const Expanded(flex: 2, child: SizedBox.shrink()),
              ],
            ),
          ],
          if (moreOpen) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _buildCheckbox(
                  label: 'TRU Care',
                  value: dep.trucareMember,
                  onChanged: (v) => setState(() => dep.trucareMember = v ?? false),
                  textCol: textCol,
                  primaryCol: primaryCol,
                  onPrimaryCol: onPrimaryCol,
                ),
                _buildCheckbox(
                  label: 'PhilHealth Member',
                  value: dep.phicMember,
                  onChanged: (v) => setState(() => dep.phicMember = v ?? false),
                  textCol: textCol,
                  primaryCol: primaryCol,
                  onPrimaryCol: onPrimaryCol,
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          _buildMoreDetailsLink(
            open: moreOpen,
            canClose: !hasMore,
            onTap: () => setState(() => dep.showMore = !moreOpen),
            primaryCol: primaryCol,
            subtextCol: subtextCol,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Layout helpers: sector chips, "More details" link, photo picker, sidebar
  // ---------------------------------------------------------------------------

  bool get _hasMoreDetails => _trucareMember || _phicMember;
  bool get _moreDetailsOpen => _showMoreDetails || _hasMoreDetails;

  /// Male / Female toggle (single choice, required) with the form's red error text.
  Widget _buildGenderField({
    Key? key,
    required String? value,
    required ValueChanged<String> onChanged,
    required Color textCol,
    required Color borderCol,
    required Color primaryCol,
    required Color subtextCol,
  }) {
    return FormField<String>(
      // Re-created whenever the choice changes, so a picked value clears the "Required" error
      key: ValueKey('$key|$value'),
      initialValue: value,
      validator: (v) => v == null ? 'Required' : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Gender *', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: subtextCol)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: _genders.map((g) {
                final on = value == g;
                return ChoiceChip(
                  label: Text(g),
                  selected: on,
                  onSelected: (_) => onChanged(g),
                  showCheckmark: true,
                  checkmarkColor: primaryCol,
                  labelStyle:
                      GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: on ? primaryCol : textCol),
                  backgroundColor: _fieldFill,
                  selectedColor: primaryCol.withValues(alpha: 0.1),
                  side: BorderSide(
                    color: field.hasError
                        ? TropaColors.errorOf(context)
                        : (on ? primaryCol.withValues(alpha: 0.45) : borderCol),
                  ),
                  shape: const StadiumBorder(),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child:
                    Text(field.errorText!, style: GoogleFonts.inter(fontSize: 11, color: TropaColors.errorOf(context))),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSectorChips({
    required Set<String> selected,
    required void Function(String sector, bool selected) onToggle,
    required Color textCol,
    required Color borderCol,
    required Color primaryCol,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _sectorOptions.map((sector) {
        final on = selected.contains(sector);
        return FilterChip(
          label: Text(sector),
          selected: on,
          onSelected: (v) => onToggle(sector, v),
          showCheckmark: true,
          checkmarkColor: primaryCol,
          labelStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: on ? primaryCol : textCol),
          backgroundColor: _fieldFill,
          selectedColor: primaryCol.withValues(alpha: 0.1),
          side: BorderSide(color: on ? primaryCol.withValues(alpha: 0.45) : borderCol),
          shape: const StadiumBorder(),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }

  Widget _buildMoreDetailsLink({
    required bool open,
    required bool canClose,
    required VoidCallback onTap,
    required Color primaryCol,
    required Color subtextCol,
  }) {
    if (open && !canClose) return const SizedBox.shrink();
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: primaryCol,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onTap,
      icon: Icon(open ? Icons.remove : Icons.add, size: 16),
      label: Text(
        open ? 'Fewer details' : 'More details (PhilHealth, TRU Care)',
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// ID photo beside the personal details.
  Widget _buildPhotoPicker(bool isDark, Color borderCol, Color textCol, Color subtextCol, Color primaryCol) {
    final hasExisting = widget.existing?.profilePictureUrl != null;
    final initials = [_firstNameCtrl.text, _lastNameCtrl.text]
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .map((n) => n[0].toUpperCase())
        .join();
    return Container(
      width: 150,
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
      decoration: BoxDecoration(
        color: TropaColors.chipOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: primaryCol.withValues(alpha: 0.12),
            backgroundImage: _avatarBytes != null
                ? MemoryImage(_avatarBytes!)
                : (hasExisting ? NetworkImage(widget.existing!.profilePictureUrl!) as ImageProvider : null),
            child: (_avatarBytes == null && !hasExisting)
                ? (initials.isNotEmpty
                    ? Text(initials,
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: primaryCol))
                    : Icon(Icons.person_outline, size: 30, color: primaryCol))
                : null,
          ),
          const SizedBox(height: 10),
          Text('ID Photo', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textCol)),
          const SizedBox(height: 2),
          Text(
            _avatarName ?? 'JPG or PNG, compressed on device',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 10.5, color: subtextCol),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryCol,
              side: BorderSide(color: primaryCol.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _isUploadingPhoto ? null : _pickAvatar,
            child: _isUploadingPhoto
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_avatarBytes != null || hasExisting ? 'Change' : 'Browse',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Everything still blocking a save, in plain words (sidebar checklist).
  List<({String label, bool done})> get _saveChecklist {
    final hasName = _lastNameCtrl.text.trim().isNotEmpty && _firstNameCtrl.text.trim().isNotEmpty;
    return [
      (label: 'Last and first name', done: hasName),
      (label: 'Birthday', done: _birthDate != null),
      (label: 'Gender', done: _gender != null),
      (label: 'Membership date', done: _membershipDate != null),
      if (_selectedSectors.contains('Student')) (label: 'Year level', done: _yearLevel != null),
      (label: 'LGU and barangay', done: _lgu.isNotEmpty && _barangay.isNotEmpty),
      (label: 'Purok', done: _purok.isNotEmpty),
      if (_isHouseholdLeader)
        for (var i = 0; i < _dependentMembers.length; i++)
          if (_dependentProblems(_dependentMembers[i]).isNotEmpty)
            (label: 'Member #${i + 1}: ${_dependentProblems(_dependentMembers[i]).join(', ')}', done: false),
    ];
  }

  Widget _buildSummarySidebar(bool isDark, Color borderCol, Color textCol, Color subtextCol, Color primaryCol) {
    const warn = Color(0xFFD97706);
    final name = [
      _lastNameCtrl.text.trim().toUpperCase(),
      [_firstNameCtrl.text, _middleNameCtrl.text]
          .map((n) => n.trim().toUpperCase())
          .where((n) => n.isNotEmpty)
          .join(' ')
    ].where((n) => n.isNotEmpty).join(', ');
    final ageText = _birthDate != null ? '${_ageOn(_birthDate!)} yrs' : 'No birthday yet';
    final householdName = widget.presetHousehold?.householdName ??
        (widget.existing != null
            ? _selectedHousehold?.householdName
            : (_isHouseholdLeader ? _generatedHouseholdName : null));
    final checklist = _saveChecklist;

    Widget heading(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(t.toUpperCase(),
              style: GoogleFonts.inter(
                  fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: subtextCol)),
        );
    Widget kv(String k, String v) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 72, child: Text(k, style: GoogleFonts.inter(fontSize: 12, color: subtextCol))),
              Expanded(child: Text(v.isEmpty ? '—' : v, style: GoogleFonts.inter(fontSize: 12, color: textCol))),
            ],
          ),
        );

    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: TropaColors.subtleOf(context),
        border: Border(left: BorderSide(color: borderCol)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading('Member'),
            Text(name.isEmpty ? 'New member' : name,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: textCol)),
            const SizedBox(height: 2),
            Text([ageText, if (_gender != null) _gender!, _joinSectors(_selectedSectors)].join(' · '),
                style: GoogleFonts.inter(fontSize: 12, color: subtextCol)),
            const SizedBox(height: 20),
            heading('Location'),
            kv('LGU', _lgu),
            kv('Barangay', _barangay),
            kv('Purok', _purok),
            const SizedBox(height: 16),
            heading('Household'),
            Text(householdName ?? 'Not a household leader',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textCol)),
            if (_isHouseholdLeader) ...[
              const SizedBox(height: 6),
              for (final d in _dependentMembers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(_dependentDisplayName(d),
                              overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: textCol))),
                      Text(d.birthDate != null ? '${_ageOn(d.birthDate!)}' : '—',
                          style: GoogleFonts.inter(fontSize: 12, color: subtextCol)),
                    ],
                  ),
                ),
              if (_dependentMembers.isEmpty)
                Text('No household members added', style: GoogleFonts.inter(fontSize: 12, color: subtextCol)),
            ],
            const SizedBox(height: 20),
            heading('Before saving'),
            for (final item in checklist)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.done ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 15, color: item.done ? const Color(0xFF1F7A4D) : warn),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item.label,
                          style: GoogleFonts.inter(fontSize: 12, color: item.done ? subtextCol : textCol)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    bool upperCase = true,
    required Color textCol,
    required Color borderCol,
    required Color fillCol,
    required Color primaryCol,
  }) {
    final subtextCol = TropaColors.textMedium(context);
    return _labeledField(
      label,
      subtextCol,
      TextFormField(
        controller: controller,
        style: GoogleFonts.inter(fontSize: 13, color: textCol),
        decoration: _searchBoxDecoration(hint, borderCol, _fieldFill, primaryCol, subtextCol),
        validator: validator,
        inputFormatters: [if (upperCase) const UpperCaseFormatter(), ...?inputFormatters],
        textCapitalization: upperCase ? TextCapitalization.characters : TextCapitalization.none,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? date,
    required String hint,
    required ValueChanged<DateTime> onDateSelected,
    VoidCallback? onCleared,
    bool isBirthDate = false,
    ValueChanged<bool>? onRangeError,
    required Color textCol,
    required Color borderCol,
    required Color fillCol,
    required Color primaryCol,
  }) {
    final subtextCol = TropaColors.textMedium(context);

    return _labeledField(
      label,
      subtextCol,
      _TypeableDateField(
        date: date,
        hint: hint,
        isRequired: label.trim().endsWith('*'),
        decoration: _searchBoxDecoration(hint, borderCol, _fieldFill, primaryCol, subtextCol),
        textStyle: GoogleFonts.inter(fontSize: 13, color: textCol),
        iconColor: textCol,
        onDateSelected: onDateSelected,
        onCleared: onCleared,
        isBirthDate: isBirthDate,
        onRangeError: onRangeError,
      ),
    );
  }

  Widget _buildCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Color textCol,
    required Color primaryCol,
    required Color onPrimaryCol,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: value,
              activeColor: primaryCol,
              checkColor: onPrimaryCol,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: textCol)),
        ],
      ),
    );
  }

  Widget _buildSmallCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Color textCol,
    required Color primaryCol,
    required Color onPrimaryCol,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: Checkbox(
              value: value,
              activeColor: primaryCol,
              checkColor: onPrimaryCol,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: textCol)),
        ],
      ),
    );
  }

  Color get _fieldFill => TropaColors.fieldFillOf(context);
}

/// Date box that accepts typing (mm/dd/yyyy, slashes added automatically)
/// or picking from the calendar button.
class _TypeableDateField extends StatefulWidget {
  final DateTime? date;
  final String hint;
  final bool isRequired;
  final InputDecoration decoration;
  final TextStyle textStyle;
  final Color iconColor;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback? onCleared;
  // Birthday mode: only dates before today and at most 100 years ago
  final bool isBirthDate;
  final ValueChanged<bool>? onRangeError;

  const _TypeableDateField({
    required this.date,
    required this.hint,
    required this.isRequired,
    required this.decoration,
    required this.textStyle,
    required this.iconColor,
    required this.onDateSelected,
    this.onCleared,
    this.isBirthDate = false,
    this.onRangeError,
  });

  @override
  State<_TypeableDateField> createState() => _TypeableDateFieldState();
}

class _TypeableDateFieldState extends State<_TypeableDateField> {
  static final _format = DateFormat('MM/dd/yyyy');
  static final _firstDate = DateTime(1900);
  static final _lastDate = DateTime(2100);

  late final TextEditingController _ctrl = TextEditingController(text: _fmt(widget.date));
  final _fieldKey = GlobalKey<FormFieldState<String>>();
  final _focus = FocusNode();
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Leaving the box with a partial or wrong date flags it right away
    _focus.addListener(() {
      if (_focus.hasFocus || _ctrl.text.isEmpty) return;
      _expandShortYear();
      _check();
    });
  }

  /// mm/dd/yy -> mm/dd/yyyy once the user is done typing (leaves the box or presses Enter).
  /// Birthdays take the latest century that keeps the date in the past (96 -> 1996, 05 -> 2005);
  /// other dates use 20yy.
  void _expandShortYear() {
    final m = RegExp(r'^(\d\d)/(\d\d)/(\d\d)$').firstMatch(_ctrl.text);
    if (m == null) return;
    final yy = int.parse(m.group(3)!);
    var year = 2000 + yy;
    if (widget.isBirthDate) {
      final candidate = _parse('${m.group(1)}/${m.group(2)}/$year');
      if (candidate == null || !candidate.isBefore(_today)) year -= 100;
    }
    final text = '${m.group(1)}/${m.group(2)}/$year';
    _ctrl.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    _handleText(text);
  }

  /// Reports the typed text to the form: a valid date is kept, an out-of-range one is dropped.
  void _handleText(String text) {
    final d = _parse(text);
    final outOfRange = d != null && _rangeError(d) != null;
    widget.onRangeError?.call(outOfRange);
    if (d != null && !outOfRange) {
      widget.onDateSelected(d);
    } else if (text.isEmpty || outOfRange) {
      // Out-of-range birthdays aren't kept, so age-based rules never see them
      widget.onCleared?.call();
    }
  }

  /// Re-runs this field's check so the red border and message update live.
  void _check() {
    final ok = _fieldKey.currentState?.validate() ?? true;
    if (mounted && _hasError == ok) setState(() => _hasError = !ok);
  }

  static String _fmt(DateTime? d) => d == null ? '' : _format.format(d);

  /// Strict mm/dd/yyyy parse within range; null if incomplete or not a real date (e.g. 02/30).
  static DateTime? _parse(String text) {
    if (text.length != 10) return null;
    try {
      final d = _format.parseStrict(text);
      return (d.isBefore(_firstDate) || d.isAfter(_lastDate)) ? null : d;
    } catch (_) {
      return null;
    }
  }

  @override
  void didUpdateWidget(covariant _TypeableDateField old) {
    super.didUpdateWidget(old);
    // Only react when the date changed from outside (calendar, voter record, form reset);
    // never overwrite what the user is typing.
    if (widget.date == old.date) return;
    final parsed = _parse(_ctrl.text);
    String? next;
    if (widget.date != null && parsed != widget.date) {
      next = _fmt(widget.date);
    } else if (widget.date == null && parsed != null && _rangeError(parsed) == null) {
      // Cleared from outside (e.g. "Save & Add Another"); keep an out-of-range entry so its error shows
      next = '';
    }
    if (next == null) return;
    final text = next;
    // Changing the text notifies the Form, which mustn't happen mid-build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _ctrl.text != text) _ctrl.text = text;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  static DateTime get _today => phToday();

  /// Why a complete, real date isn't acceptable here (birthday mode only); null when it's fine.
  String? _rangeError(DateTime d) {
    if (!widget.isBirthDate) return null;
    if (!d.isBefore(_today)) return 'Birthday must be before today';
    if (_MemberFormDialogState._ageOn(d) > 100) return 'Check the year: that makes them over 100';
    return null;
  }

  Future<void> _openCalendar() async {
    final yesterday = _today.subtract(const Duration(days: 1));
    final first = widget.isBirthDate ? DateTime(_today.year - 100, _today.month, _today.day) : _firstDate;
    final last = widget.isBirthDate ? yesterday : _lastDate;
    var initial =
        _parse(_ctrl.text) ?? widget.date ?? (widget.isBirthDate ? DateTime(_today.year - 30, 1, 1) : phToday());
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      _ctrl.text = _fmt(picked);
      widget.onRangeError?.call(false);
      widget.onDateSelected(picked);
      _check();
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorCol = TropaColors.errorOf(context);
    final showError = _hasError || (_fieldKey.currentState?.hasError ?? false);
    return TextFormField(
      key: _fieldKey,
      controller: _ctrl,
      focusNode: _focus,
      style: widget.textStyle,
      keyboardType: TextInputType.datetime,
      inputFormatters: [_DateSlashFormatter()],
      decoration: widget.decoration.copyWith(
        suffixIcon: IconButton(
          icon: Icon(showError ? Icons.event_busy_outlined : Icons.calendar_today_outlined,
              size: 18, color: showError ? errorCol : widget.iconColor),
          tooltip: 'Pick from calendar',
          onPressed: _openCalendar,
        ),
      ),
      onChanged: (text) {
        _handleText(text);
        // Complete dates are checked immediately; partial ones once the box loses focus
        if (text.length == 10 || _hasError) _check();
      },
      onFieldSubmitted: (_) {
        _expandShortYear();
        _check();
      },
      validator: (text) {
        final t = text ?? '';
        // Still typing: don't nag about an unfinished date
        if (_focus.hasFocus && t.isNotEmpty && t.length < 10) return null;
        if (t.isEmpty) return widget.isRequired ? 'Required' : null;
        final d = _parse(t);
        if (d == null) return 'Enter a valid date (mm/dd/yyyy)';
        return _rangeError(d);
      },
    );
  }
}

/// Keeps only digits and inserts slashes: 10141953 -> 10/14/1953.
class _DateSlashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buf.write('/');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// PH mobile input: digits only, +63/63/9 prefixes become 09, max 11 digits, shown as 0917 123 4567.
class _PhMobileFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = _MemberFormDialogState._phMobileDigits(newValue.text);
    if (digits.length > 11) digits = digits.substring(0, 11);
    final text = _MemberFormDialogState._formatPhMobile(digits);
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

