/// Problems in households and members shown on the For Review page (lib/views/review_view.dart).
///
/// Everything is computed here, in plain Dart, from rows the service reads from the local
/// database (see SupabaseService.getReviewItems): hash maps keep it linear over ~80k members,
/// where the same matching as SQL self-joins would be quadratic on common surnames.
library;

import '../core/ph_time.dart';

/// Problem keys, stored in `review_dismissals.flag`. Order = how serious, most serious first.
class ReviewFlags {
  static const duplicateHousehold = 'duplicate_household';
  static const dupInHousehold = 'dup_in_household';
  static const dupOtherHousehold = 'dup_other_household';
  static const severalLeaders = 'several_leaders';
  static const mergedFamilies = 'merged_families';
  static const leaderNotInHousehold = 'leader_not_in_household';
  static const noLeaderFlag = 'no_leader_flag';

  static const labels = <String, String>{
    duplicateHousehold: 'Possible duplicate household',
    dupInHousehold: 'Duplicate in household',
    dupOtherHousehold: 'Also in another household',
    severalLeaders: 'Several leaders',
    mergedFamilies: 'Other families inside',
    leaderNotInHousehold: 'Named leader not in household',
    noLeaderFlag: 'No leader',
  };

  static int rank(String key) {
    final i = labels.keys.toList().indexOf(key);
    return i < 0 ? labels.length : i;
  }
}

class ReviewFlag {
  final String key;
  final String detail;

  /// Cleared by a reviewer (a `review_dismissals` row exists for it).
  final bool cleared;

  /// Other households the detail mentions (e.g. where the same person also appears), so the
  /// page can open them.
  final List<({String id, String name})> related;

  const ReviewFlag({required this.key, required this.detail, this.cleared = false, this.related = const []});

  String get label => ReviewFlags.labels[key] ?? key;
}

class ReviewItem {
  /// 'household' or 'member', as stored in `review_dismissals.entity_type`.
  final String entityType;
  final String entityId;
  final String title;
  final String householdId;
  final String householdName;
  final String lgu;
  final String barangay;
  final String purok;
  final DateTime? encodedOn;

  /// `created_by`; empty for rows imported from the old system.
  final String encodedBy;
  final List<ReviewFlag> flags;

  const ReviewItem({
    required this.entityType,
    required this.entityId,
    required this.title,
    required this.householdId,
    required this.householdName,
    required this.lgu,
    required this.barangay,
    required this.purok,
    required this.encodedOn,
    required this.encodedBy,
    required this.flags,
  });

  bool get isHousehold => entityType == 'household';
  List<ReviewFlag> get openFlags => [for (final f in flags) if (!f.cleared) f];
  bool get fullyCleared => openFlags.isEmpty;
}

/// Households with at least this many members are checked for other families inside.
const reviewBigHousehold = 10;

/// Name suffixes: "DIOSO JR" and "DIOSO SR" are father and son, not one person.
const _suffixes = {'JR', 'JR.', 'SR', 'SR.', 'II', 'III', 'IV'};

/// Upper-cased with tidy spacing: runs of spaces become one, and a comma always reads ", "
/// (old imports have names like "ABUNDA , EDDIE  ANSARAW FAMILY").
String _norm(Object? v) => (v?.toString() ?? '')
    .toUpperCase()
    .replaceAll(RegExp(r'\s*,\s*'), ', ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

class _M {
  final String id, householdId, ln, fn, mn, bd, area, purok, createdBy;
  final bool leader;
  final DateTime? createdOn;
  final List<String> words;

  _M(Map<String, dynamic> r)
      : id = r['id'].toString(),
        householdId = (r['household_id'] ?? '').toString(),
        ln = _norm(r['lastname']),
        fn = _norm(r['firstname']),
        mn = _norm(r['middlename']),
        bd = (r['birth_date']?.toString() ?? '').trim().length >= 10
            ? r['birth_date'].toString().trim().substring(0, 10)
            : '',
        area = '${_norm(r['lgu'])}|${_norm(r['barangay'])}',
        purok = (r['purok'] ?? '').toString().trim(),
        createdBy = (r['created_by'] ?? '').toString().trim(),
        leader = r['is_household_leader'] == 1 || r['is_household_leader'] == true,
        createdOn = r['created_date'] == null ? null : parsePh(r['created_date'].toString()),
        words = _norm(r['firstname']).split(' ').where((w) => w.isNotEmpty).toList();

  String get fullName => [ '$ln,', fn, if (mn.isNotEmpty) mn].join(' ');

  String? get suffix => words.length > 1 && _suffixes.contains(words.last) ? words.last.replaceAll('.', '') : null;
}

class _H {
  final String id, name, lgu, barangay, purok, createdBy;
  final DateTime? createdOn;

  _H(Map<String, dynamic> r)
      : id = r['id'].toString(),
        name = _norm(r['household_name']),
        lgu = (r['lgu'] ?? '').toString().trim(),
        barangay = (r['barangay'] ?? '').toString().trim(),
        purok = (r['purok'] ?? '').toString().trim(),
        createdBy = (r['created_by'] ?? '').toString().trim(),
        createdOn = r['created_date'] == null ? null : parsePh(r['created_date'].toString());
}

/// The same name or a typo apart: up to 2 letters different (1 for names of 4 letters or fewer,
/// so "ANA" and "EVA" stay different people).
bool _closeName(String a, String b) {
  if (a.isEmpty || b.isEmpty) return false;
  if (a == b) return true;
  final shortest = a.length < b.length ? a.length : b.length;
  return _editDistance(a, b) <= (shortest <= 4 ? 1 : 2);
}

/// First names: close ([_closeName]), or one is the other plus more names ("JEALON" / "JEALON NATHANIEL").
bool _closeFirstName(String a, String b) =>
    _closeName(a, b) || (a.isNotEmpty && b.isNotEmpty && (a.startsWith('$b ') || b.startsWith('$a ')));

/// Birthdays that are mostly the same: at least 2 of year, month and day agree
/// (a wrong day, month or year). Unknown birthdays never match.
bool _closeBirth(String a, String b) {
  if (a.length < 10 || b.length < 10) return false;
  final x = a.split('-'), y = b.split('-');
  if (x.length != 3 || y.length != 3) return false;
  var same = 0;
  for (var i = 0; i < 3; i++) {
    if (x[i] == y[i]) same++;
  }
  return same >= 2;
}

/// Bucket keys for finding birthdays that share 2 of 3 parts: any two such dates share a key.
List<String> _birthKeys(String bd) {
  final p = bd.split('-');
  if (bd.length < 10 || p.length != 3) return const [];
  // 01-01 is how old imports filled in unknown birthdays: don't pair those across different years.
  return ['Y${p[0]}M${p[1]}', 'Y${p[0]}D${p[2]}', if (p[1] != '01' || p[2] != '01') 'M${p[1]}D${p[2]}'];
}

/// Levenshtein distance, capped: anything over 2 returns 3. It runs millions of times over a full
/// barangay list, so it reuses two rows and stops as soon as a whole row is over 2.
int _editDistance(String s, String t) {
  if ((s.length - t.length).abs() > 2) return 3;
  final a = s.codeUnits, b = t.codeUnits;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  var cur = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    cur[0] = i;
    var rowMin = i;
    for (var j = 1; j <= b.length; j++) {
      var v = prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1);
      if (prev[j] + 1 < v) v = prev[j] + 1;
      if (cur[j - 1] + 1 < v) v = cur[j - 1] + 1;
      cur[j] = v;
      if (v < rowMin) rowMin = v;
    }
    if (rowMin > 2) return 3;
    final tmp = prev;
    prev = cur;
    cur = tmp;
  }
  return prev[b.length] > 2 ? 3 : prev[b.length];
}

/// Whether two members look like one person: same barangay, and every field a possible match:
/// last, first and middle name the same or a typo apart (a missing middle name doesn't rule it
/// out), and the birthday mostly the same (2 of year, month, day). "ARMANDO" and "ARMANDO JR."
/// are father and son unless their birthdays are identical.
bool _samePerson(_M m, _M o) {
  if (m.area != o.area) return false;
  if (!_closeName(m.ln, o.ln)) return false;
  if (!_closeFirstName(m.fn, o.fn)) return false;
  if (m.mn.isNotEmpty && o.mn.isNotEmpty && !_closeName(m.mn, o.mn)) return false;
  if (!_closeBirth(m.bd, o.bd)) return false;
  return m.suffix == o.suffix || m.bd == o.bd;
}

/// [_samePerson] for `family_members` rows, used by the household comparison dialog.
bool reviewSamePerson(Map<String, dynamic> a, Map<String, dynamic> b) => _samePerson(_M(a), _M(b));

/// The member form's warning before saving someone new: [_samePerson], or, when either birthday is
/// unknown (encoders often leave it blank), the same barangay with last, first and middle name all
/// the same or a typo apart. Looser than the review page, since the encoder decides on the spot.
bool possibleDuplicateMember(Map<String, dynamic> a, Map<String, dynamic> b) {
  final m = _M(a), o = _M(b);
  if (_samePerson(m, o)) return true;
  if (m.area != o.area || (m.bd.isNotEmpty && o.bd.isNotEmpty)) return false;
  return _closeName(m.ln, o.ln) &&
      _closeFirstName(m.fn, o.fn) &&
      _closeName(m.mn, o.mn) &&
      (m.suffix == o.suffix);
}

String _date(DateTime? d) =>
    d == null ? 'unknown date' : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Builds the review list. [members] and [households] are active (non-archived) rows with the
/// columns of `family_members` / `households`; [dismissals] are `review_dismissals` rows.
/// Items whose flags are all cleared are still returned (marked cleared), for "Show cleared".
List<ReviewItem> detectReviewItems({
  required List<Map<String, dynamic>> members,
  required List<Map<String, dynamic>> households,
  required List<Map<String, dynamic>> dismissals,
}) {
  final hh = {for (final r in households) r['id'].toString(): _H(r)};
  final ms = [for (final r in members) if (hh.containsKey((r['household_id'] ?? '').toString())) _M(r)];
  final byHousehold = <String, List<_M>>{};
  for (final m in ms) {
    byHousehold.putIfAbsent(m.householdId, () => []).add(m);
  }
  final cleared = {
    for (final d in dismissals) '${d['entity_type']}|${d['entity_id']}|${d['flag']}',
  };

  final memberFlags = <String, List<ReviewFlag>>{};
  final householdFlags = <String, List<ReviewFlag>>{};
  ({String id, String name}) ref(String householdId) => (id: householdId, name: hh[householdId]?.name ?? householdId);
  void flagMember(_M m, String key, String detail, {List<({String id, String name})> related = const []}) =>
      memberFlags.putIfAbsent(m.id, () => []).add(ReviewFlag(key: key, detail: detail, related: related));
  void flagHousehold(String id, String key, String detail, {List<({String id, String name})> related = const []}) =>
      householdFlags.putIfAbsent(id, () => []).add(ReviewFlag(key: key, detail: detail, related: related));

  // 1. Saved twice in the same household: same name and birth date.
  for (final list in byHousehold.values) {
    final groups = <String, List<_M>>{};
    for (final m in list) {
      groups.putIfAbsent('${m.ln}|${m.fn}|${m.bd}', () => []).add(m);
    }
    for (final g in groups.values.where((g) => g.length > 1)) {
      for (final m in g) {
        final others = [for (final o in g) if (o != m) 'encoded ${_date(o.createdOn)}'];
        flagMember(m, ReviewFlags.dupInHousehold, 'Saved ${g.length} times in this household (also ${others.join(', ')})');
      }
    }
  }

  // 2. Same person in another household of the same barangay: every field a possible match
  //    (see _samePerson). People are bucketed by barangay and 2 of their 3 birthday parts, so
  //    only members whose birthdays could match are compared.
  final byBirth = <String, List<_M>>{};
  for (final m in ms) {
    for (final k in _birthKeys(m.bd)) {
      byBirth.putIfAbsent('${m.area}|$k', () => []).add(m);
    }
  }
  final matchedHouseholds = <String, Map<String, int>>{}; // member's household -> other household -> count
  final dupMembers = <String>{};
  for (final m in ms) {
    // The buckets only narrow the search; _samePerson decides.
    final candidates = <_M>{
      for (final k in _birthKeys(m.bd)) ...?byBirth['${m.area}|$k'],
    }.where((o) => o.householdId != m.householdId && _samePerson(m, o)).toList()
      ..sort((a, b) => (a.createdOn ?? DateTime(0)).compareTo(b.createdOn ?? DateTime(0)));
    if (candidates.isEmpty) continue;
    dupMembers.add(m.id);
    final seen = <String>{};
    for (final o in candidates) {
      if (seen.add(o.householdId)) {
        final counts = matchedHouseholds.putIfAbsent(m.householdId, () => {});
        counts[o.householdId] = (counts[o.householdId] ?? 0) + 1;
      }
    }
    final detail = candidates.take(2).map((o) {
      final name = hh[o.householdId]?.name ?? 'another household';
      return 'Also in $name as ${o.fullName} (b. ${o.bd.isEmpty ? 'no birth date' : o.bd}, encoded ${_date(o.createdOn)})';
    }).join('; ');
    flagMember(m, ReviewFlags.dupOtherHousehold, candidates.length > 2 ? '$detail; +${candidates.length - 2} more' : detail,
        related: [for (final id in {for (final o in candidates) o.householdId}) ref(id)]);
  }

  // Household checks.
  for (final entry in byHousehold.entries) {
    final h = hh[entry.key]!;
    final list = entry.value;
    final n = list.length;

    // 3. Most members already exist in other households: likely encoded twice.
    final dups = list.where((m) => dupMembers.contains(m.id)).length;
    if (n >= 2 && dups >= 2 && dups * 2 >= n) {
      final top = (matchedHouseholds[h.id]!.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(4).toList();
      final others = top.map((e) => '${hh[e.key]?.name ?? e.key} (${e.value})').join(', ');
      flagHousehold(h.id, ReviewFlags.duplicateHousehold, '$dups of $n members also in: $others',
          related: [for (final e in top) ref(e.key)]);
    }

    // Leader flags.
    final flagged = list.where((m) => m.leader).toList();
    if (flagged.isEmpty) {
      flagHousehold(h.id, ReviewFlags.noLeaderFlag, 'None of its $n members is marked as household leader');
    } else if (flagged.length > 1) {
      flagHousehold(h.id, ReviewFlags.severalLeaders,
          '${flagged.length} members marked as leader: ${flagged.map((m) => m.fullName).join('; ')}');
    }

    // The person the household is named after ("LAST, FIRST MIDDLE FAMILY").
    final named = h.name.contains(', ') && h.name.endsWith(' FAMILY');
    var nameMatches = named
        ? list.where((m) => m.ln.isNotEmpty && m.fn.isNotEmpty && h.name.startsWith('${m.ln}, ${m.fn} ')).toList()
        : <_M>[];
    // No exact match: accept the same surname with the first name spelled within 2 letters
    // ("MORALES, BENJAMEN …" vs member "BEJAMEN"), so a typo isn't reported as a missing leader.
    if (named && nameMatches.isEmpty) {
      final last = h.name.substring(0, h.name.indexOf(', '));
      final given = h.name.substring(h.name.indexOf(', ') + 2, h.name.length - ' FAMILY'.length).split(' ');
      nameMatches = list.where((m) {
        if (m.ln != last || m.words.isEmpty || m.words.length > given.length) return false;
        return _editDistance(m.fn, given.take(m.words.length).join(' ')) <= 2;
      }).toList();
    }
    _M? nameLeader;
    if (nameMatches.length == 1) {
      nameLeader = nameMatches.single;
    } else if (nameMatches.length > 1) {
      final exact = nameMatches.where((m) => h.name == '${m.fullName} FAMILY').toList();
      final pick = exact.length == 1 ? exact : nameMatches.where((m) => m.leader).toList();
      if (pick.length == 1) nameLeader = pick.single;
    }
    if (named && nameMatches.isEmpty) {
      flagHousehold(h.id, ReviewFlags.leaderNotInHousehold,
          '${h.name.substring(0, h.name.length - ' FAMILY'.length)} is not a member of this household');
    }

    // 4. Big household with other families' surnames inside.
    if (n >= reviewBigHousehold) {
      final leader = nameLeader ?? (flagged.length == 1 ? flagged.single : null);
      final leaderLn = leader?.ln ?? (named ? h.name.split(',').first.trim() : '');
      final leaderMn = leader?.mn ?? '';
      final surnames = <String, int>{};
      for (final m in list) {
        surnames[m.ln] = (surnames[m.ln] ?? 0) + 1;
      }
      final foreign = surnames.entries
          .where((e) => e.value >= 2 && e.key.isNotEmpty && e.key != leaderLn && e.key != leaderMn)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (foreign.isNotEmpty) {
        flagHousehold(h.id, ReviewFlags.mergedFamilies,
            '$n members; other surnames: ${foreign.map((e) => '${e.key} ×${e.value}').join(', ')}');
      }
    }
  }

  List<ReviewFlag> withCleared(String type, String id, List<ReviewFlag> flags) => [
        for (final f in flags..sort((a, b) => ReviewFlags.rank(a.key).compareTo(ReviewFlags.rank(b.key))))
          ReviewFlag(
              key: f.key, detail: f.detail, related: f.related, cleared: cleared.contains('$type|$id|${f.key}')),
      ];

  final items = <ReviewItem>[
    for (final e in householdFlags.entries)
      () {
        final h = hh[e.key]!;
        return ReviewItem(
          entityType: 'household',
          entityId: h.id,
          title: h.name,
          householdId: h.id,
          householdName: h.name,
          lgu: h.lgu,
          barangay: h.barangay,
          purok: h.purok,
          encodedOn: h.createdOn,
          encodedBy: h.createdBy,
          flags: withCleared('household', h.id, e.value),
        );
      }(),
    for (final m in ms)
      if (memberFlags[m.id] case final flags?)
        () {
          final h = hh[m.householdId]!;
          return ReviewItem(
            entityType: 'member',
            entityId: m.id,
            title: m.fullName,
            householdId: h.id,
            householdName: h.name,
            lgu: h.lgu,
            barangay: h.barangay,
            purok: m.purok.isNotEmpty ? m.purok : h.purok,
            encodedOn: m.createdOn,
            encodedBy: m.createdBy,
            flags: withCleared('member', m.id, flags),
          );
        }(),
  ];

  // Most serious first, then by place and name so related records sit together.
  items.sort((a, b) {
    int first(ReviewItem i) => ReviewFlags.rank((i.openFlags.isEmpty ? i.flags : i.openFlags).first.key);
    final r = first(a).compareTo(first(b));
    if (r != 0) return r;
    final p = '${a.lgu}|${a.barangay}|${a.householdName}'.compareTo('${b.lgu}|${b.barangay}|${b.householdName}');
    return p != 0 ? p : a.title.compareTo(b.title);
  });
  return items;
}
