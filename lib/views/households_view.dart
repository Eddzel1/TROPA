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

  final List<String> _barangays = [
    'All',
    'BANLAG',
    'POBLACION',
    'LILINGAYON',
    'BAROBO',
    'SINABUAGAN',
    'BATANGAN',
    'GUINOYORAN',
    'LURUGAN',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openHouseholdDialog([Household? existing]) {
    final formKey = GlobalKey<FormBuilderState>();
    Uint8List? selectedImageBytes;
    String? selectedImageName;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryCol = TropaColors.primaryOf(context);
    final onPrimaryCol = TropaColors.onPrimaryOf(context);
    final dlgBg = isDark ? TropaColors.darkSurface8dp : Colors.white;
    final dlgText = isDark ? TropaColors.darkOnSurface : TropaColors.lightOnSurface;
    final uploadBg = isDark ? TropaColors.darkSurface2dp : const Color(0xFFF1F5F9);
    final uploadBorder = isDark ? TropaColors.darkOutlineVariant : const Color(0xFFE2E8F0);

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
                  'lgu': existing?.lgu ?? 'VALENCIA CITY',
                  'barangay': existing?.barangay.isNotEmpty == true ? existing!.barangay : 'BANLAG',
                  'purok': existing?.purok ?? 'P-1',
                  'total_members': (existing?.totalMembers ?? 2).toString(),
                  'status': existing?.status ?? 'active',
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LabeledField(
                      label: 'Household Family Name *',
                      child: FormBuilderTextField(
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
                            label: 'Barangay *',
                            child: FormBuilderDropdown<String>(
                              style: TropaStyles.fieldText(context),
                              name: 'barangay',
                              decoration: TropaStyles.formField(context),
                              items: _barangays
                                  .where((b) => b != 'All')
                                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                                  .toList(),
                              validator: FormBuilderValidators.required(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LabeledField(
                            label: 'Purok *',
                            child: FormBuilderTextField(
                              style: TropaStyles.fieldText(context),
                              name: 'purok',
                              decoration: TropaStyles.formField(context, hint: 'e.g. P-1 Proper'),
                              validator: FormBuilderValidators.required(),
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
                                  selectedImageName ?? (existing?.housePictureUrl != null ? 'Photo Attached' : 'Attach House Picture (Storage Bucket: house-pictures)'),
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Accepted: JPG, PNG',
                                  style: TropaText.caption(TropaColors.darkOutline),
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
                    purok: values['purok'] as String,
                    latitude: point?.latitude,
                    longitude: point?.longitude,
                    totalMembers: int.tryParse(values['total_members'].toString()) ?? 1,
                    activeMembers: int.tryParse(values['total_members'].toString()) ?? 1,
                    status: values['status'] as String,
                    housePictureUrl: uploadedUrl,
                    createdDate: existing?.createdDate ?? phNow(),
                    updatedDate: phNow(),
                    createdBy: existing?.createdBy ?? 'Admin',
                  );

                  if (existing == null) {
                    await ref.read(householdListNotifierProvider.notifier).addHousehold(item);
                  } else {
                    await ref.read(householdListNotifierProvider.notifier).updateHousehold(item);
                  }

                  if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? TropaColors.darkOnSurface : TropaColors.lightOnSurface;
    // Keep the selection valid while locations are still loading
    final items = ['All', ...options, if (value != 'All' && !options.contains(value)) value];
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down, size: 18, color: textCol),
      dropdownColor: isDark ? TropaColors.darkSurface8dp : Colors.white,
      style: TropaStyles.fieldText(context),
      decoration: TropaStyles.filterField(context),
      items: items
          .map((o) => DropdownMenuItem(value: o, child: Text(o == 'All' ? allLabel : o, overflow: TextOverflow.ellipsis)))
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryCol = TropaColors.primaryOf(context);
    final cardBg = isDark ? TropaColors.darkSurface1dp : Colors.white;
    final borderCol = isDark ? TropaColors.darkOutlineVariant : const Color(0xFFE2E8F0);
    final textCol = isDark ? TropaColors.darkOnSurface : TropaColors.lightOnSurface;
    final subtextCol = isDark ? TropaColors.darkOnSurfaceVariant : TropaColors.lightOnSurfaceVariant;
    final locations = ref.watch(locationsProvider).valueOrNull ?? const <LocationOption>[];
    final lgus = ({for (final l in locations) if (l.lgu.isNotEmpty) l.lgu}).toList()..sort();
    final barangays = ({
      for (final l in locations)
        if (l.barangay.isNotEmpty && (filter.lgu == 'All' || l.lgu == filter.lgu)) l.barangay
    }).toList()
      ..sort();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
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

            // Search and Filters Bar
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchCtrl,
                    style: TropaStyles.fieldText(context),
                    decoration: TropaStyles.filterField(context, hint: 'Search by family or household name...', search: true).copyWith(
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
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: _filterDropdown(
                    value: filter.lgu,
                    allLabel: 'All LGUs',
                    options: lgus,
                    // Barangay list depends on the LGU, so reset it when the LGU changes
                    onChanged: (v) => _applyFilter((f) => f.copyWith(lgu: v, barangay: 'All')),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: _filterDropdown(
                    value: filter.barangay,
                    allLabel: 'All Barangays',
                    options: barangays,
                    onChanged: (v) => _applyFilter((f) => f.copyWith(barangay: v)),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Reload from Supabase',
                  onPressed: () {
                    ref.read(householdListNotifierProvider.notifier).refresh();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Table of Households
            Expanded(
              child: householdsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error loading households: $err', style: TextStyle(color: textCol))),
                data: (households) {
                  if (households.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cottage_outlined, size: 48, color: TropaColors.darkOutline),
                          const SizedBox(height: 12),
                          Text('No households found', style: TropaText.sectionTitle(textCol)),
                          const SizedBox(height: 4),
                          Text('Try adjusting your search criteria or register a new household.', style: TropaText.meta(subtextCol)),
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                              ),
                              subtitle: Text(
                                '${h.purok}, ${h.barangay}, ${h.lgu} • Click to view roster & dependents',
                                style: TropaText.meta(subtextCol),
                              ),
                              trailing: Row(
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
                                    icon: Icon(Icons.edit_outlined, size: 18, color: isDark ? null : Colors.grey[700]),
                                    tooltip: 'Edit Household',
                                    onPressed: () => _openHouseholdDialog(h),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: TropaColors.error),
                                    tooltip: 'Delete Household',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          backgroundColor: cardBg,
                                          title: Text('Delete Household?', style: TextStyle(color: textCol)),
                                          content: Text('Are you sure you want to delete ${h.householdName}?', style: TextStyle(color: subtextCol)),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: TropaColors.error))),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await ref.read(householdListNotifierProvider.notifier).deleteHousehold(h.id);
                                      }
                                    },
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
      ),
    );
  }
}
