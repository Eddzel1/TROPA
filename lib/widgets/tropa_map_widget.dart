import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../core/design_system.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import 'household_view_dialog.dart';

/// One pin per household (approximate location near its barangay center).
/// Tapping a pin lists the household's members.
class TropaMapWidget extends ConsumerStatefulWidget {
  final List<Household> households;
  final LatLng initialCenter;
  final double initialZoom;

  const TropaMapWidget({
    super.key,
    required this.households,
    this.initialCenter = const LatLng(7.9064, 125.0949), // Valencia City coordinates
    this.initialZoom = 13.0,
  });

  @override
  ConsumerState<TropaMapWidget> createState() => _TropaMapWidgetState();
}

class _TropaMapWidgetState extends ConsumerState<TropaMapWidget> {
  late final MapController _mapController;
  final LayerHitNotifier<Household> _hitNotifier = ValueNotifier(null);
  // All households drawn by one painter; rebuilt only when the household list changes
  late List<CircleMarker<Household>> _circles;
  // Tiles are cached on disk (flutter_map built-in, native only). A failed request shows a blank tile
  // once its cached copy is stale, so keep tiles fresh for 30 days to stay usable offline in the field.
  // Created once per map: TileLayer disposes its provider.
  late final _tileProvider = NetworkTileProvider(
    cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(overrideFreshAge: const Duration(days: 30)),
  );
  Household? _selected;
  List<FamilyMember>? _members;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  // Pin colors read the theme, which initState can't; this also recolors pins on light/dark switch.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _circles = _buildCircles();
  }

  @override
  void didUpdateWidget(TropaMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.households, widget.households)) _circles = _buildCircles();
  }

  @override
  void dispose() {
    _hitNotifier.dispose();
    _mapController.dispose();
    super.dispose();
  }

  List<CircleMarker<Household>> _buildCircles() => [
        for (final h in widget.households)
          CircleMarker(
            point: LatLng(h.latitude!, h.longitude!),
            radius: 7,
            color: _isActive(h) ? TropaColors.primaryOf(context) : TropaColors.tertiary,
            borderColor: Colors.white,
            borderStrokeWidth: 1.5,
            hitValue: h,
          ),
      ];

  bool _isActive(Household h) => h.status.toLowerCase() == 'active';

  Future<void> _select(Household h) async {
    setState(() {
      _selected = h;
      _members = null;
    });
    final members = await ref.read(supabaseServiceProvider).getMembers(householdId: h.id, pageSize: 100);
    // Ignore the result if another pin was tapped (or the card closed) meanwhile
    if (!mounted || _selected?.id != h.id) return;
    members.sort((a, b) {
      if (a.isHouseholdLeader != b.isHouseholdLeader) return a.isHouseholdLeader ? -1 : 1;
      return a.fullName.compareTo(b.fullName);
    });
    setState(() => _members = members);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? TropaColors.darkSurface : Colors.white;
    final borderCol = isDark ? TropaColors.darkSurfaceHighest : const Color(0xFFE2E8F0);
    final textCol = isDark ? TropaColors.darkOnSurface : TropaColors.lightOnSurface;
    final subtextCol = isDark ? TropaColors.darkOnSurfaceVariant : TropaColors.lightOnSurfaceVariant;
    final avatarBg = isDark ? TropaColors.darkSurfaceHigh : const Color(0xFFF1F5F9);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.initialCenter,
            initialZoom: widget.initialZoom,
            minZoom: 5,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tropa.v2',
              tileProvider: _tileProvider,
            ),
            ValueListenableBuilder<LayerHitResult<Household>?>(
              valueListenable: _hitNotifier,
              builder: (context, hit, child) => MouseRegion(
                cursor: hit == null ? MouseCursor.defer : SystemMouseCursors.click,
                child: child,
              ),
              child: GestureDetector(
                onTap: () {
                  final hits = _hitNotifier.value?.hitValues;
                  if (hits != null && hits.isNotEmpty) _select(hits.first);
                },
                child: CircleLayer<Household>(circles: _circles, hitNotifier: _hitNotifier),
              ),
            ),
            // Only the selected household gets a full widget marker
            if (selected != null)
              MarkerLayer(markers: [
                Marker(
                  point: LatLng(selected.latitude!, selected.longitude!),
                  width: 44,
                  height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isActive(selected) ? TropaColors.primaryOf(context) : TropaColors.tertiary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.cottage, color: Colors.black, size: 22),
                  ),
                ),
              ]),
          ],
        ),

        // Map Overlay Legend / Info
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: cardBg.withOpacity(0.95),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderCol),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _legendItem('Active Household', TropaColors.primaryOf(context), textCol),
                const SizedBox(width: 12),
                _legendItem('Inactive Household', TropaColors.tertiary, textCol),
                const SizedBox(width: 12),
                Text(
                  '${widget.households.length} pins',
                  style: TropaText.meta(subtextCol),
                ),
              ],
            ),
          ),
        ),

        // Household card with its members when a pin is tapped
        if (_selected != null)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TropaColors.primaryOf(context), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(isDark ? 0.5 : 0.1), blurRadius: 16),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: avatarBg,
                        child: Icon(Icons.cottage, color: TropaColors.primaryOf(context), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selected!.householdName,
                              overflow: TextOverflow.ellipsis,
                              style: TropaText.sectionTitle(textCol),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_selected!.purok}, ${_selected!.barangay}, ${_selected!.lgu}',
                              overflow: TextOverflow.ellipsis,
                              style: TropaText.meta(subtextCol),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final household = _selected!;
                          showDialog(
                            context: context,
                            builder: (_) => HouseholdViewDialog(household: household),
                          );
                        },
                        child: const Text('View household'),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: subtextCol),
                        onPressed: () => setState(() {
                          _selected = null;
                          _members = null;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: borderCol),
                  const SizedBox(height: 6),
                  Flexible(child: _memberList(isDark, textCol, subtextCol)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _memberList(bool isDark, Color textCol, Color subtextCol) {
    final members = _members;
    if (members == null) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text('No members recorded for this household.', style: TropaText.meta(subtextCol)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: members.length,
      itemBuilder: (context, i) {
        final m = members[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Icon(Icons.person, size: 16, color: m.isHouseholdLeader ? TropaColors.secondaryOf(context) : subtextCol),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  m.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: TropaText.bodyStrong(textCol),
                ),
              ),
              if (m.isHouseholdLeader) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: TropaColors.secondaryOf(context).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'LEADER',
                    style: TropaText.badge(isDark ? TropaColors.secondaryOf(context) : Color(0xFF059669)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(m.sector, style: TropaText.caption(subtextCol)),
            ],
          ),
        );
      },
    );
  }

  Widget _legendItem(String label, Color color, Color textCol) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TropaText.caption(textCol),
        ),
      ],
    );
  }
}
