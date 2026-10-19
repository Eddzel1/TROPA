import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../core/design_system.dart';
import '../widgets/form_fields.dart';
import '../core/geo.dart';
import '../models/models.dart';
import '../providers/household_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/voter_provider.dart';
import '../widgets/household_view_dialog.dart';
import '../core/ph_time.dart';

class HouseholdsView extends ConsumerStatefulWidget {
  const HouseholdsView({super.key});

  @override
  ConsumerState<HouseholdsView> createState() => _HouseholdsViewState();
}

class _HouseholdsViewState extends ConsumerState<HouseholdsView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openHouseholdDialog([Household? existing]) {
    final formKey = GlobalKey<FormBuilderState>();
    Uint8List? selectedImageBytes;
    String? selectedImageName;

    final primaryCol = TropaColors.primaryOf(context);
    final onPrimaryCol = TropaColors.onPrimaryOf(context);
    final dlgBg = TropaColors.cardOf(context);
    final dlgText = TropaColors.textHigh(context);
    final uploadBg = TropaColors.chipOf(context);
    final uploadBorder = TropaColors.borderOf(context);

    // LGU and barangay choices come from the locations table, keeping the household's own values
    // selectable even when they aren't listed there.
    final locations = ref.read(locationsProvider).valueOrNull ?? const <LocationOption>[];
    String norm(String? v) => (v ?? '').trim().toUpperCase();
    String? selectedLgu = norm(existing?.lgu).isNotEmpty ? norm(existing?.lgu) : null;
    String? selectedBarangay = norm(existing?.barangay).isNotEmpty ? norm(existing?.barangay) : null;
    final existingPurok = (existing?.purok ?? '').trim();
    // `locations.id` of the chosen LGU + barangay; puroks hang off it.
    String? locationId() {
      for (final l in locations) {
        if (l.lgu == selectedLgu && l.barangay == selectedBarangay && l.id.isNotEmpty) return l.id;
      }
      return null;
    }

    List<String> lguOptions() => {
          for (final l in locations)
            if (l.lgu.isNotEmpty) l.lgu,
          if (selectedLgu != null) selectedLgu!,
        }.toList()
          ..sort();
    List<String> barangayOptions() => {
          for (final l in locations)
            if (l.barangay.isNotEmpty && l.lgu == selectedLgu) l.barangay,
          if (selectedLgu == norm(existing?.lgu) && norm(existing?.barangay).isNotEmpty) norm(existing?.barangay),
        }.toList()
          ..sort();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: dlgBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            existing == null ? 'Register New Household' : 'Edit Household Profile',
            style: TropaText.dialogTitle(dlgText),
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: FormBuilder(
                key: formKey,
                initialValue: {
                  'household_name': existing?.householdName ?? '',
                  'lgu': selectedLgu,
                  'barangay': norm(existing?.barangay).isNotEmpty ? norm(existing?.barangay) : null,
                  'purok': existingPurok.isNotEmpty ? existingPurok : null,
                  'total_members': (existing?.totalMembers ?? 2).toString(),
                  'status': existing?.status ?? 'active',
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LabeledField(
                      label: 'Household Family Name *',
                      child: FormBuilderTextField(
                        inputFormatters: const [UpperCaseFormatter()],
                        textCapitalization: TextCapitalization.characters,
                        style: TropaStyles.fieldText(context),
                        name: 'household_name',
                        decoration: TropaStyles.formField(context, hint: 'e.g. DELA CRUZ, JUAN FAMILY'),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.minLength(3),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: LabeledField(
                            label: 'LGU *',
                            child: FormBuilderDropdown<String>(
                              style: TropaStyles.fieldText(context),
                              name: 'lgu',
                              isExpanded: true,
                              decoration: TropaStyles.formField(context, hint: 'Select LGU'),
                              items: lguOptions()
                                  .map((l) => DropdownMenuItem(value: l, child: Text(l, overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              validator: FormBuilderValidators.required(),
                              onChanged: (v) {
                                if (v == selectedLgu) return;
                                setDialogState(() {
                                  selectedLgu = v;
                                  selectedBarangay = null;
                                });
                                // Barangays belong to an LGU, so pick again after changing it
                                formKey.currentState?.fields['barangay']?.didChange(null);
                                formKey.currentState?.fields['purok']?.didChange(null);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LabeledField(
                            label: 'Barangay *',
                            child: FormBuilderDropdown<String>(
                              style: TropaStyles.fieldText(context),
                              name: 'barangay',
                              isExpanded: true,
                              decoration: TropaStyles.formField(context, hint: 'Select barangay'),
                              items: barangayOptions()
                                  .map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              validator: FormBuilderValidators.required(),
                              onChanged: (v) {
                                if (v == null || v == selectedBarangay) return;
                                setDialogState(() => selectedBarangay = v);
                                formKey.currentState?.fields['purok']?.didChange(null);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: LabeledField(
                            label: 'Purok *',
                            child: Consumer(builder: (context, ref, _) {
                              final locId = locationId();
                              final puroksAsync = locId == null ? null : ref.watch(puroksProvider(locId));
                              final puroks = puroksAsync?.valueOrNull ?? const <({String id, String name})>[];
                              final names = [for (final p in puroks) p.name];
                              // A saved purok that isn't in the puroks table stays selectable (it saves without a purok_id)
                              final keepExisting = existingPurok.isNotEmpty &&
                                  selectedLgu == norm(existing?.lgu) &&
                                  selectedBarangay == norm(existing?.barangay) &&
                                  !names.contains(existingPurok);
                              final String hint;
                              if (selectedBarangay == null) {
                                hint = 'Select barangay first';
                              } else if (puroksAsync?.isLoading ?? false) {
                                hint = 'Loading puroks…';
                              } else if (puroks.isEmpty) {
                                hint = 'No puroks listed';
                              } else {
                                hint = 'Select purok';
                              }
                              return FormBuilderDropdown<String>(
                                style: TropaStyles.fieldText(context),
                                name: 'purok',
                                isExpanded: true,
                                decoration: TropaStyles.formField(context, hint: hint),
                                items: [
                                  if (keepExisting)
                                    DropdownMenuItem(
                                      value: existingPurok,
                                      child: Text('$existingPurok (not in purok list)', overflow: TextOverflow.ellipsis),
                                    ),
                                  for (final n in names) DropdownMenuItem(value: n, child: Text(n, overflow: TextOverflow.ellipsis)),
                                ],
                                // Only required when this barangay actually has puroks listed
                                validator: (v) => puroks.isNotEmpty && (v == null || v.isEmpty) ? 'Required' : null,
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: LabeledField(
                            label: 'Total Members *',
                            child: FormBuilderTextField(
                              style: TropaStyles.fieldText(context),
                              name: 'total_members',
                              decoration: TropaStyles.formField(context),
                              keyboardType: TextInputType.number,
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.numeric(),
                              ]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LabeledField(
                            label: 'Status',
                            child: FormBuilderDropdown<String>(
                              style: TropaStyles.fieldText(context),
                              name: 'status',
                              decoration: TropaStyles.formField(context),
                              items: const [
                                DropdownMenuItem(value: 'active', child: Text('Active')),
                                DropdownMenuItem(value: 'relocated', child: Text('Relocated')),
                                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // House Picture Upload Button
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: uploadBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: uploadBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedImageBytes != null ? Icons.image : Icons.add_a_photo,
                            color: primaryCol,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedImageName ??
                                      (existing?.housePictureUrl != null
                                          ? 'Photo Attached'
                                          : 'Attach House Picture (Storage Bucket: house-pictures)'),
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Accepted: JPG, PNG',
                                  style: TropaText.caption(TropaColors.textDisabled(context)),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () async {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['jpg', 'jpeg', 'png'],
                                withData: true,
                              );
                              if (result != null && result.files.first.bytes != null) {
                                setDialogState(() {
                                  selectedImageBytes = result.files.first.bytes;
                                  selectedImageName = result.files.first.name;
                                });
                              }
                            },
                            child: const Text('Browse'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryCol,
                foregroundColor: onPrimaryCol,
              ),
              onPressed: () async {
                if (formKey.currentState?.saveAndValidate() == true) {
                  final values = formKey.currentState!.value;
                  final service = ref.read(supabaseServiceProvider);
                  final householdId = existing?.id ?? const Uuid().v4();

                  String? uploadedUrl = existing?.housePictureUrl;
                  if (selectedImageBytes != null) {
                    uploadedUrl = await service.uploadHousePicture(
                      householdId: householdId,
                      bytes: selectedImageBytes!,
                      extension: selectedImageName?.split('.').last ?? 'jpg',
                    );
                  }

                  // Approximate house location: keep it unless the LGU/barangay changed,
                  // otherwise a random point near the barangay center.
                  final lgu = values['lgu'] as String;
                  final barangay = values['barangay'] as String;
                  final purok = (values['purok'] as String?)?.trim() ?? '';
                  // purok_id only when the purok comes from the puroks table
                  final locId = locationId();
                  final puroks = locId == null ? const <({String id, String name})>[] : await ref.read(puroksProvider(locId).future);
                  String? purokId;
                  for (final p in puroks) {
                    if (p.name == purok) purokId = p.id;
                  }
                  final sameArea = existing != null &&
                      existing.lgu.trim().toUpperCase() == lgu.trim().toUpperCase() &&
                      existing.barangay.trim().toUpperCase() == barangay.trim().toUpperCase();
                  LatLngPoint? point = sameArea && existing.latitude != null && existing.longitude != null
                      ? (latitude: existing.latitude!, longitude: existing.longitude!)
                      : null;
                  if (point == null) {
                    final center = barangayCenter(await ref.read(locationsProvider.future), lgu, barangay);
                    if (center != null) point = jitterAround(center);
                  }

                  final item = Household(
                    id: householdId,
                    householdName: values['household_name'] as String,
                    lgu: lgu,
                    barangay: barangay,
                    purok: purok,
                    purokId: purokId,
                    householdLeaderId: existing?.householdLeaderId,
                    latitude: point?.latitude,
                    longitude: point?.longitude,
                    totalMembers: int.tryParse(values['total_members'].toString()) ?? 1,
                    activeMembers: int.tryParse(values['total_members'].toString()) ?? 1,
                    status: values['status'] as String,
                    housePictureUrl: uploadedUrl,
                    housePicturePath: existing?.housePicturePath,
                    isArchived: existing?.isArchived ?? false,
                    createdDate: existing?.createdDate ?? phNow(),
                    updatedDate: phNow(),
                    createdBy: existing?.createdBy ?? service.currentAuthUser?.email ?? '',
                  );

                  final notifier = ref.read(householdListNotifierProvider.notifier);
                  final ok = existing == null
                      ? await notifier.addHousehold(item) != null
                      : await notifier.updateHousehold(item);
                  if (!dialogCtx.mounted) return;
                  if (!ok) {
                    ScaffoldMessenger.of(dialogCtx).showSnackBar(
                      const SnackBar(content: Text('Could not save the household. Please try again.')),
                    );
                    return;
                  }
                  Navigator.of(dialogCtx).pop();
                }
              },
              child: Text(existing == null ? 'Save Household' : 'Update Record'),
            ),
          ],
        ),
      ),
    );
  }

  void _applyFilter(HouseholdFilter Function(HouseholdFilter) update) {
    ref.read(householdFilterProvider.notifier).update(update);
    ref.read(householdListNotifierProvider.notifier).refresh();
  }

  Widget _filterDropdown({
    required String value,
    required String allLabel,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    final textCol = TropaColors.textHigh(context);
    // Keep the selection valid while locations are still loading
    final items = ['All', ...options, if (value != 'All' && !options.contains(value)) value];
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down, size: 18, color: textCol),
      dropdownColor: TropaColors.cardOf(context),
      style: TropaStyles.fieldText(context),
      decoration: TropaStyles.filterField(context),
      items: items
          .map((o) =>
              DropdownMenuItem(value: o, child: Text(o == 'All' ? allLabel : o, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(householdFilterProvider);
    final householdsAsync = ref.watch(householdListNotifierProvider);
    final canDelete = ref.watch(canPermissionProvider(AppPermissions.deleteRecords));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryCol = TropaColors.primaryOf(context);
    final cardBg = TropaColors.cardOf(context);
    final borderCol = TropaColors.borderOf(context);
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final locations = ref.watch(locationsProvider).valueOrNull ?? const <LocationOption>[];
    final lgus = ({
      for (final l in locations)
        if (l.lgu.isNotEmpty) l.lgu
    }).toList()
      ..sort();
    final barangays = ({
      for (final l in locations)
        if (l.barangay.isNotEmpty && (filter.lgu == 'All' || l.lgu == filter.lgu)) l.barangay
    }).toList()
      ..sort();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(builder: (context, constraints) {
        // Phones and tablets: filters stack, row actions fold into a menu.
        final narrow = constraints.maxWidth < 900;
        final compact = TropaBreakpoints.isCompact(constraints.maxWidth);
        final searchField = TextField(
  inputFormatters: const [UpperCaseFormatter()],
  textCapitalization: TextCapitalization.characters,
  controller: _searchCtrl,
  style: TropaStyles.fieldText(context),
  decoration:
      TropaStyles.filterField(context, hint: 'Search by family or household name...', search: true)
          .copyWith(
    suffixIcon: _searchCtrl.text.isNotEmpty
        ? IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: () {
              _searchCtrl.clear();
              ref.read(householdFilterProvider.notifier).update(
                    (s) => s.copyWith(query: ''),
                  );
              ref.read(householdListNotifierProvider.notifier).refresh();
            },
          )
        : null,
  ),
  onSubmitted: (val) {
    ref.read(householdFilterProvider.notifier).update(
          (s) => s.copyWith(query: val.trim()),
        );
    ref.read(householdListNotifierProvider.notifier).refresh();
  },
);
        final lguFilter = _filterDropdown(
  value: filter.lgu,
  allLabel: 'All LGUs',
  options: lgus,
  // Barangay list depends on the LGU, so reset it when the LGU changes
  onChanged: (v) => _applyFilter((f) => f.copyWith(lgu: v, barangay: 'All')),
);
        final barangayFilter = _filterDropdown(
  value: filter.barangay,
  allLabel: 'All Barangays',
  options: barangays,
  onChanged: (v) => _applyFilter((f) => f.copyWith(barangay: v)),
);
        final archivedChip = FilterChip(
  avatar: Icon(Icons.archive_outlined, size: 16, color: filter.archived ? primaryCol : subtextCol),
  label: const Text('Archived'),
  tooltip: 'Show archived households',
  selected: filter.archived,
  showCheckmark: false,
  onSelected: (v) => _applyFilter((f) => f.copyWith(archived: v)),
);
        final refreshButton = IconButton.filledTonal(
  icon: const Icon(Icons.refresh, size: 20),
  tooltip: 'Reload from Supabase',
  onPressed: () {
    ref.read(householdListNotifierProvider.notifier).refresh();
  },
);

        return Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header (new households and members are created from the Add Member form)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Households Directory',
                  style: TropaText.pageTitle(textCol),
                ),
                Text(
                  'Manage residential units, family clusters and purok assignments',
                  style: TropaText.meta(subtextCol),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search and Filters Bar (stacks on phones and tablets)
            if (!narrow)
              Row(
                children: [
                  Expanded(flex: 3, child: searchField),
                  const SizedBox(width: 14),
                  Expanded(flex: 2, child: lguFilter),
                  const SizedBox(width: 14),
                  Expanded(flex: 2, child: barangayFilter),
                  if (canDelete) ...[
                    const SizedBox(width: 12),
                    archivedChip,
                  ],
                  const SizedBox(width: 12),
                  refreshButton,
                ],
              )
            else ...[
              Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 8),
                  refreshButton,
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: lguFilter),
                  const SizedBox(width: 10),
                  Expanded(child: barangayFilter),
                  if (canDelete && !compact) ...[
                    const SizedBox(width: 10),
                    archivedChip,
                  ],
                ],
              ),
              if (canDelete && compact) ...[
                const SizedBox(height: 8),
                archivedChip,
              ],
            ],
            const SizedBox(height: 20),

            // Table of Households
            Expanded(
              child: householdsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) =>
                    Center(child: Text('Error loading households: $err', style: TextStyle(color: textCol))),
                data: (households) {
                  if (households.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cottage_outlined, size: 48, color: TropaColors.textDisabled(context)),
                          const SizedBox(height: 12),
                          Text(filter.archived ? 'No archived households' : 'No households found',
                              style: TropaText.sectionTitle(textCol)),
                          const SizedBox(height: 4),
                          Text('Try adjusting your search criteria or register a new household.',
                              style: TropaText.meta(subtextCol)),
                        ],
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderCol),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ListView.separated(
                        itemCount: households.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: borderCol),
                        itemBuilder: (context, index) {
                          final h = households[index];
                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => HouseholdViewDialog(household: h),
                                );
                              },
                              contentPadding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: 8),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: primaryCol.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.cottage, color: primaryCol, size: 22),
                              ),
                              title: Text(
                                h.householdName,
                                style: TropaText.bodyStrong(textCol),
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    narrow
                                        ? '${h.purok}, ${h.barangay}, ${h.lgu}'
                                        : '${h.purok}, ${h.barangay}, ${h.lgu} • Click to view roster & dependents',
                                    style: TropaText.meta(subtextCol),
                                  ),
                                  if (narrow) ...[
                                    const SizedBox(height: 6),
                                    Wrap(spacing: 6, runSpacing: 4, children: [
                                      TropaBadge('${h.totalMembers} members', color: subtextCol),
                                      TropaBadge(
                                        h.status.toUpperCase(),
                                        color: h.status == 'active' ? TropaColors.secondaryStrongOf(context) : Colors.grey,
                                      ),
                                    ]),
                                  ],
                                ],
                              ),
                              trailing: narrow
                                  ? PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert, size: 18, color: TropaColors.textMedium(context)),
                                      tooltip: 'Household actions',
                                      onSelected: (v) => switch (v) {
                                        'roster' => showDialog(
                                            context: context,
                                            builder: (_) => HouseholdViewDialog(household: h),
                                          ),
                                        'edit' => _openHouseholdDialog(h),
                                        'archive' => _toggleArchived(context, h),
                                        _ => _confirmDelete(context, h),
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(value: 'roster', child: Text('View Roster & Add Dependents')),
                                        const PopupMenuItem(value: 'edit', child: Text('Edit Household')),
                                        if (canDelete)
                                          PopupMenuItem(
                                              value: 'archive',
                                              child: Text(h.isArchived ? 'Restore Household' : 'Archive Household')),
                                        if (canDelete)
                                          const PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Delete Household', style: TextStyle(color: TropaColors.error))),
                                      ],
                                    )
                                  : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TropaBadge('${h.totalMembers} members', color: subtextCol),
                                  const SizedBox(width: 10),
                                  TropaBadge(
                                    h.status.toUpperCase(),
                                    color: h.status == 'active' ? TropaColors.secondaryStrongOf(context) : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Icons.people_outline, size: 19, color: primaryCol),
                                    tooltip: 'View Roster & Add Dependents',
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => HouseholdViewDialog(household: h),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined, size: 18, color: TropaColors.textMedium(context)),
                                    tooltip: 'Edit Household',
                                    onPressed: () => _openHouseholdDialog(h),
                                  ),
                                  if (canDelete)
                                    IconButton(
                                      icon: Icon(h.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                                          size: 18, color: TropaColors.textMedium(context)),
                                      tooltip: h.isArchived ? 'Restore Household' : 'Archive Household',
                                      onPressed: () => _toggleArchived(context, h),
                                    ),
                                  if (canDelete)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: TropaColors.error),
                                      tooltip: 'Delete Household',
                                      onPressed: () => _confirmDelete(context, h),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
      }),
    );
  }

  Future<void> _toggleArchived(BuildContext context, Household h) async {
    final cardBg = TropaColors.cardOf(context);
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final archive = !h.isArchived;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: cardBg,
        title: Text(archive ? 'Archive Household?' : 'Restore Household?',
            style: TextStyle(color: textCol)),
        content: Text(
          archive
              ? 'Archive ${h.householdName}? The household and all of its members will be hidden. You can restore them from the Archived filter.'
              : 'Restore ${h.householdName} and all of its members?',
          style: TextStyle(color: subtextCol),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(archive ? 'Archive' : 'Restore')),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await ref
        .read(householdListNotifierProvider.notifier)
        .setHouseholdArchived(h, archive);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? '${h.householdName} ${archive ? 'archived' : 'restored'} with its members'
          : 'Could not ${archive ? 'archive' : 'restore'} ${h.householdName}'),
    ));
  }

  Future<void> _confirmDelete(BuildContext context, Household h) async {
    final cardBg = TropaColors.cardOf(context);
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: cardBg,
        title: Text('Delete Household?', style: TextStyle(color: textCol)),
        content: Text('Are you sure you want to delete ${h.householdName}?',
            style: TextStyle(color: subtextCol)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child:
                  const Text('Delete', style: TextStyle(color: TropaColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(householdListNotifierProvider.notifier).deleteHousehold(h.id);
    }
  }
}
