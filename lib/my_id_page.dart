import 'package:flutter/material.dart';

import 'tropa_id/tropa_id.dart';

/// Example screen: the member's digital ID, tap to flip, plus a
/// "Save as image" action that exports both sides at print resolution.
class MyIdPage extends StatefulWidget {
  const MyIdPage({super.key});

  @override
  State<MyIdPage> createState() => _MyIdPageState();
}

class _MyIdPageState extends State<MyIdPage> {
  final _frontKey = GlobalKey();
  final _backKey = GlobalKey();

  // Replace with the logged-in member's data from your backend.
  final member = TropaMember(
    firstName: 'Rogelio Neil',
    middleInitial: 'P',
    lastName: 'Roque',
    idNumber: 'TRP-2600001',
    memberType: 'Household Leader',
    address: 'P-15 Malingon, Bagontaas, Valencia City',
    birthDate: DateTime(1969, 7, 25),
    dateIssued: DateTime(2026, 10, 17),
    validUntil: DateTime(2029, 12, 31),
    photo: const AssetImage('assets/tropa_id/sample_photo.jpg'),
    // photo: NetworkImage(user.photoUrl),
    // signature: NetworkImage(user.signatureUrl),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My TROPA ID')),
      body: Stack(
        children: [
          // Copies used only for exporting, parked off-screen to the left.
          // They are still painted (Offstage or Opacity 0 would skip painting,
          // and the capture would fail).
          Positioned(
            left: -4000,
            top: 0,
            child: ExcludeSemantics(
              child: SizedBox(
              width: 856,
              child: Column(
                children: [
                  TropaIdCapture(
                    captureKey: _frontKey,
                    child: TropaIdCardFront(member: member),
                  ),
                  TropaIdCapture(
                    captureKey: _backKey,
                    child: TropaIdCardBack(member: member),
                  ),
                ],
              ),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TropaIdFlipCard(member: member),
              const SizedBox(height: 12),
              const Text('Tap the card to see the back', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _export,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Save as image'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _export() async {
    final front = await captureTropaIdPng(_frontKey, dpi: 300);
    final back = await captureTropaIdPng(_backKey, dpi: 300);
    // Save or share the bytes, e.g. with the share_plus or
    // image_gallery_saver packages, or upload them to your server for printing.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Front ${front.lengthInBytes ~/ 1024} KB, back ${back.lengthInBytes ~/ 1024} KB')),
    );
  }
}
