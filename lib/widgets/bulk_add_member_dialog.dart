import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/design_system.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/member_provider.dart';
import '../core/ph_time.dart';
import 'form_fields.dart';
import 'keyboard_safe_body.dart';

class BulkMemberRowData {
  String id;
  TextEditingController firstnameCtrl;
  TextEditingController lastnameCtrl;
  TextEditingController middlenameCtrl;
  TextEditingController ageCtrl;
  String sector;
  bool isHouseholdLeader;
  bool isCoopMember;
  bool isVoter;
  bool phicMember;
  bool trucareMember;

  BulkMemberRowData({
    required this.id,
    String firstname = '',
    String lastname = '',
    String middlename = '',
    String age = '',
    this.sector = 'General',
    this.isHouseholdLeader = false,
    this.isCoopMember = true,
    this.isVoter = true,
    this.phicMember = false,
    this.trucareMember = false,
  })  : firstnameCtrl = TextEditingController(text: firstname),
        lastnameCtrl = TextEditingController(text: lastname),
        middlenameCtrl = TextEditingController(text: middlename),
        ageCtrl = TextEditingController(text: age);

  void dispose() {
    firstnameCtrl.dispose();
    lastnameCtrl.dispose();
    middlenameCtrl.dispose();
    ageCtrl.dispose();
  }
}

class BulkAddMemberDialog extends ConsumerStatefulWidget {
  final Household? presetHousehold;

  const BulkAddMemberDialog({
    super.key,
    this.presetHousehold,
  });

  @override
  ConsumerState<BulkAddMemberDialog> createState() => _BulkAddMemberDialogState();
}

class _BulkAddMemberDialogState extends ConsumerState<BulkAddMemberDialog> {
  Household? _selectedHousehold;
  List<Household> _householdOptions = [];
  bool _isLoadingHouseholds = false;
  bool _isSaving = false;

  final List<BulkMemberRowData> _rows = [];

  final List<String> _sectors = [
    'General',
    'Youth',
    'Senior Citizen',
    'PWD',
    'Solo Parent',
    'Farmer',
    'Fisherfolk',
    'Women',
    'Transport / Driver',
    'Vendor / Small Business',
  ];

  @override
  void initState() {
    super.initState();
    _selectedHousehold = widget.presetHousehold;
    _loadHouseholds();

    // Start with 3 blank rows for quick rapid entry
    _addRow();
    _addRow();
    _addRow();
  }

  @override
  void dispose() {
    for (var r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _loadHouseholds() async {
    setState(() => _isLoadingHouseholds = true);
    try {
      final service = ref.read(supabaseServiceProvider);
      final list = await service.getHouseholds(pageSize: 100);
      if (mounted) {
        setState(() {
          _householdOptions = list;
          if (_selectedHousehold == null && list.isNotEmpty) {
            _selectedHousehold = list.first;
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingHouseholds = false);
    }
  }

  void _addRow() {
    setState(() {
      _rows.add(BulkMemberRowData(
        id: const Uuid().v4(),
        isHouseholdLeader: _rows.isEmpty, // default first row as leader
      ));
    });
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  Future<void> _saveBulkBatch() async {
    if (_selectedHousehold == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or assign a Household.'), backgroundColor: TropaColors.error),
      );
      return;
    }

    final validRows =
        _rows.where((r) => r.firstnameCtrl.text.trim().isNotEmpty && r.lastnameCtrl.text.trim().isNotEmpty).toList();

    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter at least one member with First Name and Last Name.'),
            backgroundColor: TropaColors.error),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final members = validRows.map((r) {
        return FamilyMember(
          id: r.id,
          householdId: _selectedHousehold!.id,
          firstname: r.firstnameCtrl.text.trim(),
          lastname: r.lastnameCtrl.text.trim(),
          middlename: r.middlenameCtrl.text.trim().isNotEmpty ? r.middlenameCtrl.text.trim() : null,
          lgu: _selectedHousehold!.lgu,
          barangay: _selectedHousehold!.barangay,
          purok: _selectedHousehold!.purok,
          sector: r.sector,
          age: int.tryParse(r.ageCtrl.text.trim()),
          isHouseholdLeader: r.isHouseholdLeader,
          isCooperativeMember: r.isCoopMember,
          isVoter: r.isVoter,
          phicMember: r.phicMember,
          trucareMember: r.trucareMember,
          createdDate: phNow(),
          updatedDate: phNow(),
        );
      }).toList();

      final created = await ref.read(memberListNotifierProvider.notifier).addMembersBulk(members);

      if (mounted) {
        Navigator.of(context).pop(created);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully registered batch of ${created.length} members to ${_selectedHousehold!.householdName}!'),
            backgroundColor: TropaColors.secondaryOf(context),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving bulk batch: $e'), backgroundColor: TropaColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dlgBg = TropaColors.cardOf(context);
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final cardSectionBg = TropaColors.subtleOf(context);
    final borderCol = TropaColors.borderOf(context);

    return AlertDialog(
      backgroundColor: dlgBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: TropaColors.primaryOf(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.table_chart, color: TropaColors.primaryOf(context), size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bulk TROPA Member Registration Grid',
                    style: TropaText.dialogTitle(textCol),
                  ),
                  Text(
                    'Rapid multi-row data entry for family dependents and cluster saturation',
                    style: TropaText.caption(subtextCol),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.close, color: subtextCol, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 1080,
        // Keeps its 540 px on desktop; scrolls when a phone keyboard leaves less room.
        child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 540),
        child: KeyboardSafeBody(
        minHeight: 540,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Household Selector Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardSectionBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderCol),
              ),
              child: Row(
                children: [
                  Icon(Icons.cottage, color: TropaColors.primaryOf(context), size: 20),
                  const SizedBox(width: 10),
                  Text('Target Household:', style: TropaText.bodyStrong(textCol)),
                  const SizedBox(width: 14),
                  if (widget.presetHousehold != null)
                    Expanded(
                      child: Text(
                        '${widget.presetHousehold!.householdName} (${widget.presetHousehold!.purok}, ${widget.presetHousehold!.barangay})',
                        style: TropaText.bodyStrong(TropaColors.primaryOf(context)),
                      ),
                    )
                  else
                    Expanded(
                      child: DropdownButtonFormField<Household>(
                        value: _selectedHousehold,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText:
                              _isLoadingHouseholds ? 'Loading households...' : 'Select Shared Household for Batch...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          suffixIcon: _isLoadingHouseholds
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : null,
                        ),
                        items: _householdOptions.map((h) {
                          return DropdownMenuItem<Household>(
                            value: h,
                            child:
                                Text('${h.householdName} (${h.purok}, ${h.barangay})', style: TropaText.meta(textCol)),
                          );
                        }).toList(),
                        onChanged: (h) => setState(() => _selectedHousehold = h),
                      ),
                    ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TropaColors.primaryOf(context).withValues(alpha: 0.15),
                      foregroundColor: TropaColors.primaryOf(context),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Row'),
                    onPressed: _addRow,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Spreadsheet-like Grid
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: dlgBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderCol),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 1040,
                      child: ListView.separated(
                        itemCount: _rows.length + 1,
                        separatorBuilder: (_, __) => Divider(height: 1, color: borderCol),
                        itemBuilder: (context, idx) {
                          // Header Row
                          if (idx == 0) {
                            return Container(
                              color: cardSectionBg,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  SizedBox(width: 32, child: Text('#', style: TropaText.tableHeader(subtextCol))),
                                  SizedBox(
                                      width: 140,
                                      child: Text('FIRST NAME *', style: TropaText.tableHeader(subtextCol))),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                      width: 140, child: Text('LAST NAME *', style: TropaText.tableHeader(subtextCol))),
                                  const SizedBox(width: 8),
                                  SizedBox(width: 110, child: Text('MIDDLE', style: TropaText.tableHeader(subtextCol))),
                                  const SizedBox(width: 8),
                                  SizedBox(width: 60, child: Text('AGE', style: TropaText.tableHeader(subtextCol))),
                                  const SizedBox(width: 8),
                                  SizedBox(width: 140, child: Text('SECTOR', style: TropaText.tableHeader(subtextCol))),
                                  const SizedBox(width: 8),
                                  SizedBox(width: 65, child: Text('LEADER', style: TropaText.tableHeader(subtextCol))),
                                  SizedBox(
                                      width: 85, child: Text('TROPA MEMBER', style: TropaText.tableHeader(subtextCol))),
                                  SizedBox(width: 65, child: Text('VOTER', style: TropaText.tableHeader(subtextCol))),
                                  SizedBox(width: 65, child: Text('PHIC', style: TropaText.tableHeader(subtextCol))),
                                  SizedBox(width: 65, child: Text('TRUCARE', style: TropaText.tableHeader(subtextCol))),
                                  const SizedBox(width: 40),
                                ],
                              ),
                            );
                          }

                          final r = _rows[idx - 1];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              children: [
                                SizedBox(width: 32, child: Text('$idx', style: TropaText.meta(subtextCol))),
                                SizedBox(
                                  width: 140,
                                  child: TextField(
                                    inputFormatters: const [UpperCaseFormatter()],
                                    textCapitalization: TextCapitalization.characters,
                                    controller: r.firstnameCtrl,
                                    style: TropaText.meta(textCol),
                                    decoration: const InputDecoration(
                                      hintText: 'First name',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 140,
                                  child: TextField(
                                    inputFormatters: const [UpperCaseFormatter()],
                                    textCapitalization: TextCapitalization.characters,
                                    controller: r.lastnameCtrl,
                                    style: TropaText.meta(textCol),
                                    decoration: const InputDecoration(
                                      hintText: 'Last name',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 110,
                                  child: TextField(
                                    inputFormatters: const [UpperCaseFormatter()],
                                    textCapitalization: TextCapitalization.characters,
                                    controller: r.middlenameCtrl,
                                    style: TropaText.meta(textCol),
                                    decoration: const InputDecoration(
                                      hintText: 'Middle name',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 60,
                                  child: TextField(
                                    controller: r.ageCtrl,
                                    keyboardType: TextInputType.number,
                                    style: TropaText.meta(textCol),
                                    decoration: const InputDecoration(
                                      hintText: 'Age',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 140,
                                  child: DropdownButtonFormField<String>(
                                    value: r.sector,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                    items: _sectors
                                        .map((s) => DropdownMenuItem(
                                            value: s, child: Text(s, style: const TextStyle(fontSize: 11))))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => r.sector = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 65,
                                  child: Checkbox(
                                    value: r.isHouseholdLeader,
                                    onChanged: (val) => setState(() => r.isHouseholdLeader = val ?? false),
                                  ),
                                ),
                                SizedBox(
                                  width: 85,
                                  child: Checkbox(
                                    value: r.isCoopMember,
                                    onChanged: (val) => setState(() => r.isCoopMember = val ?? false),
                                  ),
                                ),
                                SizedBox(
                                  width: 65,
                                  child: Checkbox(
                                    value: r.isVoter,
                                    onChanged: (val) => setState(() => r.isVoter = val ?? false),
                                  ),
                                ),
                                SizedBox(
                                  width: 65,
                                  child: Checkbox(
                                    value: r.phicMember,
                                    onChanged: (val) => setState(() => r.phicMember = val ?? false),
                                  ),
                                ),
                                SizedBox(
                                  width: 65,
                                  child: Checkbox(
                                    value: r.trucareMember,
                                    onChanged: (val) => setState(() => r.trucareMember = val ?? false),
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: TropaColors.error),
                                    onPressed: () => _removeRow(idx - 1),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        )),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: TropaColors.primaryOf(context),
            foregroundColor: TropaColors.onPrimaryOf(context),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.save, size: 18),
          label: _isSaving
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Save Batch (${_rows.where((r) => r.firstnameCtrl.text.trim().isNotEmpty).length} TROPA Members)'),
          onPressed: _isSaving ? null : _saveBulkBatch,
        ),
      ],
    );
  }
}
