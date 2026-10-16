import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../core/design_system.dart';
import '../widgets/form_fields.dart';
import '../models/models.dart';
import '../providers/dues_provider.dart';
import '../core/ph_time.dart';

class DuesCollectionView extends ConsumerStatefulWidget {
  const DuesCollectionView({super.key});

  @override
  ConsumerState<DuesCollectionView> createState() => _DuesCollectionViewState();
}

class _DuesCollectionViewState extends ConsumerState<DuesCollectionView> {
  final _searchCtrl = TextEditingController();
  final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
  final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openPaymentDialog() {
    final formKey = GlobalKey<FormBuilderState>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryCol = TropaColors.primaryOf(context);
    final onPrimaryCol = TropaColors.onPrimaryOf(context);
    final dlgBg = isDark ? TropaColors.darkSurface8dp : Colors.white;
    final dlgText = isDark ? TropaColors.darkOnSurface : TropaColors.lightOnSurface;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: dlgBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log Dues Collection / Contribution',
          style: TropaText.dialogTitle(dlgText),
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: FormBuilder(
              key: formKey,
              initialValue: {
                'amount': '250.00',
                'payment_month': formatPh(DateFormat('yyyy-MM'), phNow()),
                'months_covered': '1',
                'payment_method': 'Cash',
                'reference_number': 'OR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                'member_id': 'm-valencia-01',
                'household_id': 'hh-valencia-01',
                'notes': 'Monthly mutual aid cooperative dues',
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LabeledField(
                    label: 'Amount (PHP) *',
                    child: FormBuilderTextField(
                      style: TropaStyles.fieldText(context),
                      name: 'amount',
                      decoration: TropaStyles.formField(context).copyWith(prefixText: '₱ '),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.numeric(),
                        FormBuilderValidators.min(1),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: LabeledField(
                          label: 'Payment Month (YYYY-MM) *',
                          child: FormBuilderTextField(
                            style: TropaStyles.fieldText(context),
                            name: 'payment_month',
                            decoration: TropaStyles.formField(context),
                            validator: FormBuilderValidators.required(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabeledField(
                          label: 'Months Covered *',
                          child: FormBuilderTextField(
                            style: TropaStyles.fieldText(context),
                            name: 'months_covered',
                            decoration: TropaStyles.formField(context),
                            keyboardType: TextInputType.number,
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.integer(),
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: LabeledField(
                          label: 'Payment Method *',
                          child: FormBuilderDropdown<String>(
                            style: TropaStyles.fieldText(context),
                            name: 'payment_method',
                            decoration: TropaStyles.formField(context),
                            items: const [
                              DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                              DropdownMenuItem(value: 'GCash', child: Text('GCash')),
                              DropdownMenuItem(value: 'Maya', child: Text('Maya')),
                              DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                            ],
                            validator: FormBuilderValidators.required(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabeledField(
                          label: 'Receipt / Reference #',
                          child: FormBuilderTextField(
                            style: TropaStyles.fieldText(context),
                            name: 'reference_number',
                            decoration: TropaStyles.formField(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  LabeledField(
                    label: 'Notes / Remarks',
                    child: FormBuilderTextField(
                      style: TropaStyles.fieldText(context),
                      name: 'notes',
                      decoration: TropaStyles.formField(context),
                      maxLines: 2,
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
                final v = formKey.currentState!.value;
                final payment = DuesPayment(
                  id: const Uuid().v4(),
                  memberId: v['member_id']?.toString() ?? 'mem-default',
                  householdId: v['household_id']?.toString() ?? 'hh-default',
                  amount: double.tryParse(v['amount'].toString()) ?? 250.0,
                  paymentMonth: v['payment_month'] as String,
                  monthsCovered: int.tryParse(v['months_covered'].toString()) ?? 1,
                  paymentDate: phNow(),
                  paymentMethod: v['payment_method'] as String,
                  referenceNumber: v['reference_number'] as String?,
                  notes: v['notes'] as String?,
                  status: 'completed',
                  collectedBy: 'Staff',
                  createdBy: 'Staff',
                  createdDate: phNow(),
                  updatedDate: phNow(),
                );

                await ref.read(duesListNotifierProvider.notifier).recordPayment(payment);
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              }
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duesAsync = ref.watch(duesListNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? TropaColors.darkSurface1dp : Colors.white;
    final borderCol = isDark ? TropaColors.darkOutlineVariant : const Color(0xFFE2E8F0);
    final textCol = isDark ? TropaColors.darkOnSurface : TropaColors.lightOnSurface;
    final subtextCol = isDark ? TropaColors.darkOnSurfaceVariant : TropaColors.lightOnSurfaceVariant;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dues & Ledger', style: TropaText.pageTitle(textCol)),
                    Text('Mutual aid dues, monthly contributions, and receipt ledger auditing', style: TropaText.meta(subtextCol)),
                  ],
                ),
                ElevatedButton.icon(
                  style: TropaStyles.primaryAction(context),
                  icon: const Icon(Icons.add_card, size: 18),
                  label: const Text('Log Collection'),
                  onPressed: _openPaymentDialog,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: TropaStyles.fieldText(context),
                    decoration: TropaStyles.filterField(context, hint: 'Search by reference number or payment month...', search: true),
                    onSubmitted: (val) {
                      ref.read(duesFilterProvider.notifier).update((s) => s.copyWith(query: val.trim()));
                      ref.read(duesListNotifierProvider.notifier).refresh();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Reload Ledger',
                  onPressed: () => ref.read(duesListNotifierProvider.notifier).refresh(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Ledger List
            Expanded(
              child: duesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error loading ledger: $err', style: TextStyle(color: textCol))),
                data: (payments) {
                  if (payments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, size: 48, color: TropaColors.darkOutline),
                          const SizedBox(height: 12),
                          Text('No ledger entries yet', style: TropaText.sectionTitle(textCol)),
                          const SizedBox(height: 4),
                          Text('Log your first contribution using the button above.', style: TropaText.meta(subtextCol)),
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
                        itemCount: payments.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: borderCol),
                        itemBuilder: (context, index) {
                          final p = payments[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: TropaColors.secondaryOf(context).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.receipt, color: TropaColors.secondaryOf(context), size: 22),
                            ),
                            title: Row(
                              children: [
                                Text(currencyFormat.format(p.amount), style: TropaText.sectionTitle(TropaColors.secondaryStrongOf(context)).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                                const SizedBox(width: 12),
                                TropaBadge('Month: ${p.paymentMonth}', color: subtextCol),
                              ],
                            ),
                            subtitle: Text(
                              'Method: ${p.paymentMethod} • Ref: ${p.referenceNumber ?? "N/A"} • ${formatPh(dateFormat, p.paymentDate)}',
                              style: TropaText.meta(subtextCol),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: TropaColors.error),
                              tooltip: 'Void Record',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Void Ledger Payment?'),
                                    content: Text('Delete receipt ${p.referenceNumber}?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: TropaColors.error))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref.read(duesListNotifierProvider.notifier).deletePayment(p.id);
                                }
                              },
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
