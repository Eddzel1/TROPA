import 'package:flutter/widgets.dart';

/// Data shown on a TROPA member ID card.
class TropaMember {
  const TropaMember({
    required this.firstName,
    this.middleInitial = '',
    required this.lastName,
    required this.idNumber,
    required this.memberType,
    required this.address,
    this.birthDate,
    required this.dateIssued,
    required this.validUntil,
    this.photo,
    this.memberSince,
    this.status = 'ACTIVE',
    this.signature,
    this.qrData,
  });

  final String firstName;

  /// Single letter, with or without the dot ("P" or "P.").
  final String middleInitial;
  final String lastName;

  /// e.g. "TRP-2600001". Also used for the barcode.
  final String idNumber;

  /// e.g. "Household Leader".
  final String memberType;

  /// "Purok, Barangay, LGU", e.g. "P-15 Malingon, Bagontaas, Valencia City".
  final String address;

  /// Null prints a dash.
  final DateTime? birthDate;
  final DateTime dateIssued;
  final DateTime validUntil;

  /// Cardholder photo (NetworkImage, FileImage, MemoryImage, AssetImage...).
  /// Null, or an image that fails to load, shows a person icon.
  final ImageProvider? photo;

  /// Year shown as "SINCE ####". Defaults to the year of [dateIssued].
  final int? memberSince;

  /// Status chip next to the ID number, e.g. "ACTIVE", "EXPIRED".
  final String status;

  /// Captured signature image (transparent PNG works best).
  /// If null, the signature line is left blank for signing the printed card.
  final ImageProvider? signature;

  /// What the QR code on the back encodes. Defaults to [idNumber].
  /// In production use a verification URL or signed token, not raw personal data.
  final String? qrData;

  String get _mi {
    final s = middleInitial.trim().replaceAll('.', '');
    return s.isEmpty ? '' : '$s.';
  }

  String get fullName =>
      [firstName, if (_mi.isNotEmpty) _mi, lastName].join(' ');

  /// First line of the big name block: "ROGELIO NEIL P."
  String get nameLine1 =>
      [firstName, if (_mi.isNotEmpty) _mi].join(' ').toUpperCase();

  /// Second line of the big name block: "ROQUE"
  String get nameLine2 => lastName.toUpperCase();

  int get sinceYear => memberSince ?? dateIssued.year;

  String get qrPayload => qrData ?? idNumber;
}

/// Formats a date like "25 JUL 1969".
String formatIdDate(DateTime d) {
  const months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];
  return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
}

/// Details printed on the back of every card.
class TropaIssuer {
  const TropaIssuer({
    this.issuingOffice = '[ISSUING OFFICE]',
    this.officeAddress = '[OFFICE ADDRESS]',
    this.hotline = '[HOTLINE]',
    this.authorizedSignature,
  });

  final String issuingOffice;
  final String officeAddress;
  final String hotline;

  /// Optional image of the authorized officer's signature.
  final ImageProvider? authorizedSignature;
}
