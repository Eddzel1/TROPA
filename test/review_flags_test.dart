import 'package:flutter_test/flutter_test.dart';
import 'package:tropa_v2/services/review_flags.dart';

Map<String, dynamic> hh(String id, String name, {String brgy = 'LUMBO'}) => {
      'id': id,
      'household_name': name,
      'lgu': 'VALENCIA CITY',
      'barangay': brgy,
      'purok': 'P-2A TAGOSTOS',
      'created_date': '2026-07-24T13:51:54+08:00',
      'created_by': '',
    };

var _seq = 0;
Map<String, dynamic> mem(String household, String last, String first,
        {String? middle, String? birth, bool leader = false, String brgy = 'LUMBO', String? id}) =>
    {
      'id': id ?? 'm${_seq++}',
      'household_id': household,
      'lastname': last,
      'firstname': first,
      'middlename': middle,
      'birth_date': birth,
      'lgu': 'VALENCIA CITY',
      'barangay': brgy,
      'purok': 'P-2A TAGOSTOS',
      'is_household_leader': leader ? 1 : 0,
      'created_date': '2026-07-27T14:38:34+08:00',
      'created_by': '',
    };

ReviewItem? item(List<ReviewItem> items, String id) => items.where((i) => i.entityId == id).firstOrNull;
Set<String> keys(ReviewItem? i) => {for (final f in i?.openFlags ?? const <ReviewFlag>[]) f.key};

void main() {
  test('flags a member saved twice in one household (the Meriem case)', () {
    final items = detectReviewItems(
      households: [hh('h1', 'NAVALES, MERIEM MADERSE FAMILY')],
      members: [
        mem('h1', 'NAVALES', 'MERIEM', middle: 'MADERSE', birth: '1978-06-02', leader: true, id: 'a'),
        mem('h1', 'NAVALES', 'MERIEM', middle: 'MADERSE', birth: '1978-06-02', id: 'b'),
      ],
      dismissals: [],
    );
    expect(keys(item(items, 'a')), contains(ReviewFlags.dupInHousehold));
    expect(keys(item(items, 'b')), contains(ReviewFlags.dupInHousehold));
    expect(item(items, 'h1'), isNull, reason: 'leader is named and flagged once');
  });

  group('household imported twice (the Pateña/Dagwayan case)', () {
    final households = [
      hh('A', 'PATEÑA, CHARLENE DAGWAYA FAMILY'),
      hh('S', 'DAGWAYAN, SHERLY CLARO FAMILY'),
      hh('B', 'PATEÑA, CHARLENE DAGWAYAN FAMILY'),
    ];
    final members = [
      mem('A', 'PATEÑA', 'CHARLENE', middle: 'DAGWAYA', leader: true),
      mem('A', 'PATEÑA', 'JESSON', middle: 'CALINGASAG', birth: '2002-10-20'),
      mem('A', 'PATEÑA', 'ZEPHANIAH ZYRA', birth: '2023-12-12'),
      mem('S', 'DAGWAYAN', 'SHERLY', middle: 'CLARO', birth: '1976-04-23', leader: true),
      mem('S', 'DAGWAYAN', 'DIOSO JR', middle: 'CLARO', birth: '2006-10-23'),
      mem('S', 'DAGWAYAN', 'DIOSO SR', middle: 'CHAVEZ', birth: '1972-11-25'),
      mem('B', 'PATEÑA', 'JESSON', middle: 'CALINGCAG', birth: '2002-10-20', id: 'b-jesson'),
      mem('B', 'PATEÑA', 'ZEPHANIAH ZAYRA', middle: 'DAGWAYAN', birth: '2023-12-12', id: 'b-zeph'),
      mem('B', 'DAGWAYAN', 'SHERLY', middle: 'CLARO', birth: '1976-05-23', id: 'b-sherly'),
      mem('B', 'DAGWAYAN', 'DIOSO JR', middle: 'CLARO', birth: '2000-10-23', id: 'b-dioso'),
      mem('B', 'BARREDO', 'JOVEN', middle: 'ALEJAN', id: 'b-joven'),
    ];

    test('flags the copy household and its members', () {
      final items = detectReviewItems(households: households, members: members, dismissals: []);
      expect(keys(item(items, 'B')),
          containsAll([ReviewFlags.duplicateHousehold, ReviewFlags.leaderNotInHousehold, ReviewFlags.noLeaderFlag]));
      for (final id in ['b-jesson', 'b-zeph', 'b-sherly', 'b-dioso']) {
        expect(keys(item(items, id)), contains(ReviewFlags.dupOtherHousehold), reason: id);
      }
      expect(item(items, 'b-joven'), isNull, reason: 'no counterpart to match');
      expect(item(items, 'b-sherly')!.flags.first.detail, contains('DAGWAYAN, SHERLY CLARO FAMILY'));
      // The page links to the households named in the detail.
      expect(item(items, 'b-sherly')!.flags.first.related.map((r) => r.id), ['S']);
      expect(item(items, 'B')!.flags.first.related.map((r) => r.id), containsAll(['A', 'S']));
    });

    test('JR and SR of the same name are different people', () {
      final items = detectReviewItems(households: households, members: members, dismissals: []);
      final dioso = item(items, 'b-dioso')!.flags.first.detail;
      expect(dioso, contains('DIOSO JR'));
      expect(dioso, isNot(contains('DIOSO SR')));
    });

    test('ignores matches in another barangay', () {
      final items = detectReviewItems(
        households: [hh('X', 'CRUZ, ANA FAMILY'), hh('Y', 'CRUZ, ANA FAMILY', brgy: 'POBLACION')],
        members: [
          mem('X', 'CRUZ', 'ANA', leader: true, birth: '1990-01-01'),
          mem('Y', 'CRUZ', 'ANA', leader: true, birth: '1990-01-01', brgy: 'POBLACION'),
        ],
        dismissals: [],
      );
      expect(items, isEmpty);
    });

    test('clearing hides a problem; a new problem on the same record shows again', () {
      final cleared = [
        {'entity_type': 'household', 'entity_id': 'B', 'flag': ReviewFlags.duplicateHousehold},
        {'entity_type': 'household', 'entity_id': 'B', 'flag': ReviewFlags.leaderNotInHousehold},
        {'entity_type': 'household', 'entity_id': 'B', 'flag': ReviewFlags.noLeaderFlag},
      ];
      final items = detectReviewItems(households: households, members: members, dismissals: cleared);
      expect(item(items, 'B')!.fullyCleared, isTrue);

      // Two members get marked as leader later: a new problem the reviewer hasn't seen.
      final changed = [
        for (final m in members)
          if (m['id'] == 'b-sherly' || m['id'] == 'b-dioso') {...m, 'is_household_leader': 1} else m,
      ];
      final again = detectReviewItems(households: households, members: changed, dismissals: cleared);
      expect(keys(item(again, 'B')), {ReviewFlags.severalLeaders});
    });
  });

  test('same birth date: twins are not flagged, a misspelled first name is', () {
    final items = detectReviewItems(
      households: [
        hh('J', 'BOYLES, JOHNNY HERMOSO FAMILY'),
        hh('Z', 'BOYLES, ZYDEL HELMOSO FAMILY'),
        hh('H', 'BARREDO, HONEY JANE CLARO FAMILY'),
        hh('C', 'PATEÑA, CHARLENE DAGWAYAN FAMILY'),
      ],
      members: [
        mem('J', 'BOYLES', 'JOHNNY', middle: 'HERMOSO', birth: '1981-06-25', leader: true, id: 'johnny'),
        mem('Z', 'BOYLES', 'ZYDEL', middle: 'HELMOSO', birth: '1981-06-25', leader: true, id: 'zydel'),
        mem('H', 'BARREDO', 'JUVEN', middle: 'ALEJAN', birth: '1990-02-17', leader: true, id: 'juven'),
        mem('C', 'BARREDO', 'JOVEN', middle: 'ALEJAN', birth: '1990-02-17', id: 'joven'),
      ],
      dismissals: [],
    );
    expect(keys(item(items, 'zydel')), isNot(contains(ReviewFlags.dupOtherHousehold)));
    expect(keys(item(items, 'johnny')), isNot(contains(ReviewFlags.dupOtherHousehold)));
    expect(keys(item(items, 'joven')), contains(ReviewFlags.dupOtherHousehold));
  });

  test('a name and the same name with JR are father and son', () {
    final items = detectReviewItems(
      households: [hh('A', 'BORE, ARMANDO LAGNASA FAMILY'), hh('O', 'ODTOHAN, CRISTINE MABAYLAN FAMILY')],
      members: [
        mem('A', 'BORE', 'ARMANDO', middle: 'LAGNASA', birth: '1968-03-01', leader: true, id: 'father'),
        mem('O', 'ODTOHAN', 'CRISTINE', middle: 'MABAYLAN', leader: true),
        mem('O', 'BORE', 'ARMANDO JR.', middle: 'SAMPIT', birth: '1994-05-12', id: 'son'),
      ],
      dismissals: [],
    );
    expect(item(items, 'father'), isNull);
    expect(item(items, 'son'), isNull);
  });

  test('a typo between the household name and its leader is not a missing leader', () {
    final items = detectReviewItems(
      households: [hh('M', 'MORALES, BENJAMEN DAITOL FAMILY'), hh('P', 'PEREZ, ANA FAMILY')],
      members: [
        mem('M', 'MORALES', 'BEJAMEN', middle: 'DAITOL', leader: true),
        mem('M', 'MORALES', 'JOHN MARK', middle: 'SUASO'),
        mem('P', 'PEREZ', 'ROSA', leader: true), // different person: still flagged
      ],
      dismissals: [],
    );
    expect(item(items, 'M'), isNull);
    expect(keys(item(items, 'P')), {ReviewFlags.leaderNotInHousehold});
  });

  test('extra spaces in a household name are not a missing leader', () {
    final items = detectReviewItems(
      households: [hh('A', 'ABUNDA , EDDIE  ANSARAW FAMILY')],
      members: [
        mem('A', 'ABUNDA', 'EDDIE', middle: 'ANSARAW', leader: true),
        mem('A', 'ABUNDA', 'MIKE ', middle: 'SUMAGPI'),
      ],
      dismissals: [],
    );
    expect(items, isEmpty);
  });

  test('every field must be a possible match: last, first, middle name and birthday', () {
    Map<String, dynamic> johnny(String middle, String birth) => mem('X', 'BOYLES', 'JOHNNY', middle: middle, birth: birth);
    // Same first and last name, but middle name and birthday disagree: father and son, not one person.
    expect(reviewSamePerson(johnny('HERMOSO', '1981-06-25'), johnny('CORMINAL', '2007-03-31')), isFalse);
    // Middle name agrees but the birthday is entirely different.
    expect(reviewSamePerson(johnny('HERMOSO', '1981-06-25'), johnny('HERMOSO', '2007-03-31')), isFalse);
    // Typos in every name, and the day wrong: still a possible match.
    expect(
        reviewSamePerson(mem('A', 'PATEÑA', 'JESSON', middle: 'CALINGASAG', birth: '2002-10-20'),
            mem('B', 'PATENA', 'JESON', middle: 'CALINGCAG', birth: '2002-10-02')),
        isTrue);
    // An unknown birthday can't be a match.
    expect(reviewSamePerson(mem('A', 'CRUZ', 'ANA'), mem('B', 'CRUZ', 'ANA')), isFalse);
    // Short names allow only 1 letter difference.
    expect(reviewSamePerson(mem('A', 'CRUZ', 'ANA', birth: '1990-01-01'), mem('B', 'CRUZ', 'EVA', birth: '1990-01-01')),
        isFalse);
  });

  test('the comparison dialog uses the same rule as the review page', () {
    final sherly = mem('S', 'DAGWAYAN', 'SHERLY', birth: '1976-04-23');
    expect(reviewSamePerson(sherly, mem('B', 'DAGWAYAN', 'SHERLY', birth: '1976-05-23')), isTrue);
    expect(reviewSamePerson(mem('J', 'BOYLES', 'JOHNNY', birth: '1981-06-25'), mem('Z', 'BOYLES', 'ZYDEL', birth: '1981-06-25')),
        isFalse);
    expect(reviewSamePerson(mem('A', 'BORE', 'ARMANDO'), mem('O', 'BORE', 'ARMANDO JR.')), isFalse);
    expect(reviewSamePerson(sherly, mem('X', 'DAGWAYAN', 'SHERLY', brgy: 'POBLACION')), isFalse);
  });

  test('flags other families inside a big household', () {
    final members = [
      mem('H', 'CLARO', 'JEALON', middle: 'TAGOC', leader: true),
      for (var i = 0; i < 5; i++) mem('H', 'CLARO', 'KID$i', middle: 'TAGOC'),
      mem('H', 'TAGOC', 'MARLENE'), // leader's middle name: his mother's side, not flagged
      mem('H', 'TAGOC', 'LOLA'),
      mem('H', 'BARREDO', 'HONEY JANE'),
      mem('H', 'BARREDO', 'JUVEN'),
    ];
    final items = detectReviewItems(
      households: [hh('H', 'CLARO, JEALON TAGOC FAMILY')],
      members: members,
      dismissals: [],
    );
    final flag = item(items, 'H')!.flags.single;
    expect(flag.key, ReviewFlags.mergedFamilies);
    expect(flag.detail, contains('BARREDO ×2'));
    expect(flag.detail, isNot(contains('TAGOC')));
  });
}
