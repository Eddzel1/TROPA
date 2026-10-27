import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/design_system.dart';
import '../models/models.dart';
import '../tropa_id/tropa_id.dart';
import '../widgets/form_fields.dart';
import '../widgets/tropa_animated_logo.dart';
import 'member_id_view.dart';

/// One row from the `public_member_search` or `public_household_members` RPC.
class _PublicMatch {
  final Map<String, dynamic> row;
  final String name;
  final String location;
  final String? householdId;
  final String? household;
  final String? leader;
  final bool isLeader;
  final bool isMember;
  final DateTime? birthDate;
  final String? contact;
  final String? idNumber;
  final bool isVoter;
  final String? voterBarangay;

  /// Card data for the View ID screen (the row has the columns [tropaMemberFrom] reads).
  FamilyMember get member => FamilyMember.fromJson(row);

  _PublicMatch.fromJson(Map<String, dynamic> j)
      : row = j,
        birthDate = DateTime.tryParse('${j['birth_date'] ?? ''}'),
        contact = (j['contact_number'] as String?)?.trim(),
        idNumber = (j['id_number'] as String?)?.trim(),
        isVoter = j['is_voter'] == true,
        voterBarangay = (j['voter_barangay'] as String?)?.trim(),
        name = [j['firstname'], j['middlename'], j['lastname'], j['extension']]
            .whereType<String>()
            .where((s) => s.trim().isNotEmpty)
            .join(' '),
        location = [
          if ((j['purok'] as String?)?.trim().isNotEmpty ?? false) 'Purok ${j['purok']}',
          j['barangay'],
          j['lgu'],
        ].whereType<String>().where((s) => s.trim().isNotEmpty).join(', '),
        householdId = j['household_id'] as String?,
        household = j['household_name'] as String?,
        leader = j['leader_name'] as String?,
        isLeader = j['is_household_leader'] == true,
        isMember = j['is_cooperative_member'] == true;
}

/// Public page (no sign-in), shared by link: look up a person by name to see their household and
/// TROPA status. Reads through the `public_member_search` / `public_search_locations` RPCs, never the
/// local database (empty when signed out).
class PublicSearchView extends StatefulWidget {
  const PublicSearchView({super.key});

  @override
  State<PublicSearchView> createState() => _PublicSearchViewState();
}

class _PublicSearchViewState extends State<PublicSearchView> {
  static const _minChars = 3;

  final _lastNameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  Timer? _nameDebounce;
  // Ignores responses to searches that were typed over before they came back.
  int _requestId = 0;

  String _lgu = 'All';
  String _barangay = 'All';
  List<({String lgu, String barangay})> _locations = const [];

  bool _searched = false;
  bool _loading = false;
  String? _error;
  List<_PublicMatch> _results = const [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _nameDebounce?.cancel();
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      final rows = await Supabase.instance.client.rpc('public_search_locations');
      if (!mounted) return;
      setState(() => _locations = [
            for (final r in rows as List) (lgu: '${r['lgu']}', barangay: '${r['barangay']}'),
          ]);
    } catch (e) {
      // Dropdowns stay at "All"; name search still works.
      debugPrint('Public search locations failed: $e');
    }
  }

  int get _nameLength =>
      _lastNameCtrl.text.trim().length + _firstNameCtrl.text.trim().length + _middleNameCtrl.text.trim().length;

  void _onNameChanged() {
    _nameDebounce?.cancel();
    _nameDebounce = Timer(const Duration(milliseconds: 400), _search);
  }

  Future<void> _search() async {
    _nameDebounce?.cancel();
    final id = ++_requestId;
    if (_nameLength < _minChars) {
      setState(() {
        _searched = false;
        _loading = false;
        _error = null;
        _results = const [];
      });
      return;
    }
    setState(() {
      _searched = true;
      _loading = true;
      _error = null;
    });
    try {
      final rows = await Supabase.instance.client.rpc('public_member_search', params: {
        'p_last': _lastNameCtrl.text.trim(),
        'p_first': _firstNameCtrl.text.trim(),
        'p_middle': _middleNameCtrl.text.trim(),
        'p_lgu': _lgu == 'All' ? '' : _lgu,
        'p_barangay': _barangay == 'All' ? '' : _barangay,
      });
      if (!mounted || id != _requestId) return;
      setState(() {
        _loading = false;
        _results = (rows as List).map((r) => _PublicMatch.fromJson(Map<String, dynamic>.from(r as Map))).toList();
      });
    } catch (e) {
      debugPrint('Public search failed: $e');
      if (!mounted || id != _requestId) return;
      setState(() {
        _loading = false;
        _results = const [];
        _error = 'Search is unavailable right now. Check your internet connection and try again.';
      });
    }
  }

  Widget _nameField(TextEditingController ctrl, String hint) {
    return TextField(
      inputFormatters: const [UpperCaseFormatter()],
      textCapitalization: TextCapitalization.characters,
      controller: ctrl,
      style: TropaText.body(TropaColors.textHigh(context)),
      decoration: TropaStyles.filterField(context, hint: hint, search: true),
      textInputAction: TextInputAction.search,
      onChanged: (_) => _onNameChanged(),
      onSubmitted: (_) => _search(),
    );
  }

  Widget _filterDropdown({
    required String value,
    required String allLabel,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    final textCol = TropaColors.textHigh(context);
    final style = TropaText.body(textCol);
    return DropdownButtonFormField<String>(
      value: options.contains(value) ? value : 'All',
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down, size: 18, color: textCol),
      decoration: TropaStyles.filterField(context),
      dropdownColor: TropaColors.cardOf(context),
      style: style,
      items: [
        DropdownMenuItem(value: 'All', child: Text(allLabel, style: style, overflow: TextOverflow.ellipsis)),
        ...options
            .map((o) => DropdownMenuItem(value: o, child: Text(o, style: style, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  void _showHousehold(_PublicMatch leader) {
    final members = Supabase.instance.client
        .rpc('public_household_members', params: {'p_household_id': leader.householdId})
        .then((rows) => (rows as List).map((r) => Map<String, dynamic>.from(r as Map)).toList());
    final title = leader.household?.trim().isNotEmpty ?? false ? leader.household!.trim() : leader.name;

    showDialog(
      context: context,
      builder: (ctx) {
        final textCol = TropaColors.textHigh(ctx);
        final subCol = TropaColors.textMedium(ctx);
        return AlertDialog(
          backgroundColor: TropaColors.cardOf(ctx),
          title: Text(title.toUpperCase(), style: TropaText.dialogTitle(textCol)),
          content: SizedBox(
            width: 480,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: members,
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  debugPrint('Public household members failed: ${snap.error}');
                  return Text('Could not load the household. Try again.', style: TropaText.body(subCol));
                }
                final rows = snap.data!;
                if (rows.isEmpty) return Text('No members listed.', style: TropaText.body(subCol));
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('${rows.length} ${rows.length == 1 ? 'member' : 'members'}', style: TropaText.caption(subCol)),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: TropaColors.borderOf(ctx)),
                        itemBuilder: (ctx, i) {
                          final m = _PublicMatch.fromJson(rows[i]);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(m.name.toUpperCase(), style: TropaText.bodyStrong(textCol)),
                                          if (m.isLeader) TropaBadge('LEADER', color: TropaColors.primaryOf(ctx)),
                                          if (m.isMember)
                                            const TropaBadge('TROPA MEMBER', color: TropaColors.tropaGreen),
                                        ],
                                      ),
                                      ..._personalDetails(m, subCol),
                                    ],
                                  ),
                                ),
                                if (m.idNumber?.isNotEmpty ?? false) ...[
                                  const SizedBox(width: 8),
                                  _viewIdButton(m),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        );
      },
    );
  }

  /// Birthday, contact number and voter lines; blanks show a dash so it's clear nothing is on file.
  List<Widget> _personalDetails(_PublicMatch m, Color subCol) {
    final voter = !m.isVoter
        ? 'No'
        : (m.voterBarangay?.isNotEmpty ?? false)
            ? 'Yes (${m.voterBarangay})'
            : 'Yes';
    return [
      for (final line in [
        'Birthday: ${m.birthDate == null ? '—' : formatIdDate(m.birthDate!)}',
        'Contact no.: ${(m.contact?.isNotEmpty ?? false) ? m.contact : '—'}',
        // Older servers don't send is_voter yet; leave the line out until the migration runs.
        if (m.row.containsKey('is_voter')) 'Registered voter: $voter',
      ]) ...[
        const SizedBox(height: 2),
        Text(line, style: TropaText.meta(subCol)),
      ],
    ];
  }

  /// Opens the member's TROPA ID (flip card + print), the same screen staff use.
  /// Soft filled button that sits top-right of a card or popup row, apart from the status badges.
  Widget _viewIdButton(_PublicMatch m) => FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(0, 34),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.badge_outlined, size: 16),
        label: Text('View ID', style: TropaText.action()),
        onPressed: () => showMemberIdDialog(context, m.member),
      );

  Widget _message(IconData icon, String text) {
    final c = TropaColors.textMedium(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 36, color: c),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center, style: TropaText.body(c)),
        ],
      ),
    );
  }

  Widget _resultCard(_PublicMatch m) {
    final textCol = TropaColors.textHigh(context);
    final subCol = TropaColors.textMedium(context);
    final household = [
      if (m.household?.trim().isNotEmpty ?? false) m.household!.trim(),
      if (!m.isLeader && (m.leader?.trim().isNotEmpty ?? false)) 'Leader: ${m.leader!.trim()}',
    ].join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TropaColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TropaColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name on the left, View ID pinned top-right so it doesn't crowd the badges.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(m.name.toUpperCase(), style: TropaText.sectionTitle(textCol)),
                ),
              ),
              if (m.idNumber?.isNotEmpty ?? false) ...[
                const SizedBox(width: 12),
                _viewIdButton(m),
              ],
            ],
          ),
          if (m.location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(m.location, style: TropaText.meta(subCol)),
          ],
          if (household.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('Household: $household', style: TropaText.meta(subCol)),
          ],
          ..._personalDetails(m, subCol),
          if (m.isMember || m.isLeader) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (m.isMember) const TropaBadge('TROPA MEMBER', color: TropaColors.tropaGreen),
                if (m.isLeader)
                  m.householdId == null
                      ? TropaBadge('HOUSEHOLD LEADER', color: TropaColors.primaryOf(context))
                      : Tooltip(
                          message: 'Show household members',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _showHousehold(m),
                            child: TropaBadge(
                              'HOUSEHOLD LEADER',
                              color: TropaColors.primaryOf(context),
                              icon: Icons.groups_outlined,
                            ),
                          ),
                        ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultsBody() {
    if (!_searched) {
      return _message(Icons.search, 'Type at least $_minChars letters of a name.');
    }
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) return _message(Icons.cloud_off_outlined, _error!);
    if (_results.isEmpty) return _message(Icons.person_search_outlined, 'No one found.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            _results.length >= 20
                ? 'Showing the first 20 matches. Type more of the name to narrow it down.'
                : '${_results.length} ${_results.length == 1 ? 'match' : 'matches'}',
            style: TropaText.caption(TropaColors.textMedium(context)),
          ),
        ),
        ..._results.map(_resultCard),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<TropaBrand>();
    final compact = context.isCompactScreen;
    final lgus = ({for (final l in _locations) l.lgu}).toList()..sort();
    final barangays = ({
      for (final l in _locations)
        if (_lgu == 'All' || l.lgu == _lgu) l.barangay
    }).toList()
      ..sort();

    return Scaffold(
      backgroundColor: brand?.sidebarBg ?? TropaColors.backgroundOf(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Container(
                padding: EdgeInsets.all(compact ? 16 : 24),
                decoration: BoxDecoration(
                  color: TropaColors.cardOf(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TropaColors.borderOf(context), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: TropaAnimatedLogo(loop: true)),
                    const SizedBox(height: 20),
                    Text('Find a TROPA member', textAlign: TextAlign.center, style: TropaText.pageTitle(TropaColors.textHigh(context))),
                    const SizedBox(height: 4),
                    Text(
                      'Search by name to see a person\'s household and membership.',
                      textAlign: TextAlign.center,
                      style: TropaText.body(TropaColors.textMedium(context)),
                    ),
                    const SizedBox(height: 20),

                    // Row 1: names (phones put Last Name on its own line)
                    if (compact) ...[
                      _nameField(_lastNameCtrl, 'Last Name'),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        if (!compact) ...[
                          Expanded(child: _nameField(_lastNameCtrl, 'Last Name')),
                          const SizedBox(width: 10),
                        ],
                        Expanded(child: _nameField(_firstNameCtrl, 'First Name')),
                        const SizedBox(width: 10),
                        Expanded(child: _nameField(_middleNameCtrl, 'Middle Name')),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 2: location
                    Row(
                      children: [
                        Expanded(
                          child: _filterDropdown(
                            value: _lgu,
                            allLabel: 'All LGUs',
                            options: lgus,
                            // Barangay list depends on the LGU, so reset it when the LGU changes
                            onChanged: (v) {
                              setState(() {
                                _lgu = v;
                                _barangay = 'All';
                              });
                              _search();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _filterDropdown(
                            value: _barangay,
                            allLabel: 'All Barangays',
                            options: barangays,
                            onChanged: (v) {
                              setState(() => _barangay = v);
                              _search();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _resultsBody(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
