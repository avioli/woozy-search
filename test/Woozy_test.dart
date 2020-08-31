import 'package:woozy_search/woozy_search.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('Basic tests', () {
    final woozy = Woozy();

    setUp(() {
      woozy.setEntries(['foo', 'bar']);
    });

    test('first test', () {
      final records = woozy.search('foo');
      expect(records.length, 2);

      // perfect match return score 1.0
      final firstRecord = records.first;
      expect(firstRecord.score, 1.0);
      expect(firstRecord.text, 'foo');

      // worst match return score 0.0
      final secondRecord = records.last;
      expect(secondRecord.score, 0.0);
      expect(secondRecord.text, 'bar');
    });

    test('empty query', () {
      final records = woozy.search('');
      expect(records.length, 2);
    });

    test('associated value should be `null`', () {
      final records = woozy.search('foo');
      expect(records.length, 2);

      final firstRecord = records.first;
      expect(firstRecord.value, null);

      final secondRecord = records.last;
      expect(secondRecord.value, null);
    });
  });

  group('Long and short queries', () {
    final woozy = Woozy();

    setUp(() {
      woozy.setEntries(['sun', 'sunflower']);
    });

    test('In favor of shorter word when query is short', () {
      final records = woozy.search('su');
      expect(records.first.text, 'sun');
      expect(records.last.text, 'sunflower');
    });

    test('In favor of longer word when query is long', () {
      final records = woozy.search('lots of sunflowers');
      expect(records.first.text, 'sunflower');
      expect(records.last.text, 'sun');
    });
  });

  group('Limit the number of matches output', () {
    test('Positive number', () {
      final woozy = Woozy(limit: 5);
      woozy.addEntries(List.filled(10, 'Foo'));
      final records = woozy.search('Foo');
      expect(records.length, 5);
    });

    test('Zero', () {
      expect(() => Woozy(limit: 0), throwsA(isA<AssertionError>()));
    });

    test('Negative number', () {
      expect(() => Woozy(limit: -5), throwsA(isA<AssertionError>()));
    });
  });

  group('Associated values', () {
    test('`null` values', () {
      final woozy = Woozy();

      woozy.addEntry('foo');
      woozy.addEntry('bar');
      final records = woozy.search('f');
      expect(records.first.value, null);
    });

    test('integers', () {
      final woozy = Woozy();

      woozy.addEntry('foo', value: 0);
      woozy.addEntry('bar', value: 1);
      final records = woozy.search('f');
      expect(records.first.value, 0);
    });

    test('UUIDs', () {
      final woozy = Woozy();
      final fooId = Uuid();
      final barId = Uuid();

      woozy.addEntry('foo', value: fooId);
      woozy.addEntry('bar', value: barId);
      final records = woozy.search('f');
      expect(records.first.value, fooId);
    });
  });

  group('Case sensitivity', () {
    test('case insensitive', () {
      final woozy = Woozy();
      woozy.addEntries(['FOO', 'Boo']);
      final records = woozy.search('foo');
      expect(records.first.text, 'FOO');
    });

    test('case insensitive', () {
      final woozy = Woozy(caseSensitive: true);
      woozy.addEntries(['FOO', 'Boo']);
      final records = woozy.search('foo');
      expect(records.first.text, 'Boo');
    });
  });

  group('SingleScoreProcessor:', () {
    test('ExactWord', () {
      final woozy = Woozy(processor: SingleScoreProcessor(ExactScore()));
      woozy.addEntries(['foo', 'boo', 'fun', 'funny']);
      {
        final records = woozy.search('foo');
        expect(records.first.text, 'foo');
        expect(records.first.score, 1.0);
        expect(records[1].score, 0.0);
      }
      {
        final records = woozy.search('BOO');
        expect(records.first.text, 'boo');
        expect(records.first.score, 1.0);
        expect(records[1].score, 0.0);
      }
      {
        final records = woozy.search('funny');
        expect(records.first.text, 'funny');
        expect(records.first.score, 1.0);
        expect(records[1].score, 0.0);
      }
    });

    test('StartsWithWord', () {
      final woozy = Woozy(processor: SingleScoreProcessor(StartsWithScore()));
      woozy.addEntries(['foo', 'boo', 'fun', 'funny']);
      {
        final records = woozy.search('f');
        expect(records.map((r) => r.text).take(3), ['foo', 'fun', 'funny']);
        expect(records[0].score, closeTo(0.333, 0.001));
        expect(records[1].score, closeTo(0.333, 0.001));
        expect(records[2].score, closeTo(0.2, 0.001));
        expect(records[3].score, 0.0);
      }
      {
        final records = woozy.search('fu');
        expect(records.map((r) => r.text).take(2), ['fun', 'funny']);
        expect(records[0].score, closeTo(0.667, 0.001));
        expect(records[1].score, closeTo(0.400, 0.001));
        expect(records[2].score, 0.0);
      }
      {
        final records = woozy.search('B');
        expect(records.first.text, 'boo');
        expect(records[0].score, closeTo(0.333, 0.001));
        expect(records[1].score, 0.0);
      }
    });

    test('ContainsWord', () {
      final woozy = Woozy(processor: SingleScoreProcessor(ContainsScore()));
      woozy.addEntries(['foo', 'boo', 'fun', 'funny']);
      {
        final records = woozy.search('oo');
        expect(records.map((r) => r.text).take(2), ['foo', 'boo']);
        expect(records[0].score, closeTo(0.444, 0.001));
        expect(records[1].score, closeTo(0.444, 0.001));
        expect(records[2].score, 0.0);
      }
      {
        final records = woozy.search('F');
        expect(records.map((r) => r.text).take(3), ['foo', 'fun', 'funny']);
        expect(records[0].score, closeTo(0.333, 0.001));
        expect(records[1].score, closeTo(0.333, 0.001));
        expect(records[2].score, closeTo(0.2, 0.001));
        expect(records[3].score, 0.0);
      }
      {
        final records = woozy.search('un');
        expect(records.map((r) => r.text).take(2), ['fun', 'funny']);
        expect(records[0].score, closeTo(0.444, 0.001));
        expect(records[1].score, closeTo(0.32, 0.001));
        expect(records[2].score, 0.0);
      }
      {
        final records = woozy.search('b');
        expect(records.first.text, 'boo');
        expect(records[0].score, closeTo(0.333, 0.001));
        expect(records[2].score, 0.0);
      }
    });
  });

  group('FirstWinsProcessor:', () {
    Woozy woozy;
    setUp(() {
      final processor = FirstWinsProcessor(
          [ExactScore(), StartsWithScore(), ContainsScore()]);
      woozy = Woozy(processor: processor);
      woozy.addEntries([
        /**/ 'Et sunt sint deserunt ipsum do enim dolore consequat sunt sint adipisicing ipsum.',
        //                                   enim        Cons                       ci
        //                                   exact       start                      contains
        /**/ 'Consequat enim id laborum dolor sunt ut.',
        //    Cons      enim
        //    start     exact
        /**/ 'Enim id anim veniam elit duis enim id cillum aliqua irure exercitation elit magna.',
        //    Enim                          enim    ci                      ci
        //    exact                         exact   start                   contains
      ]);
    });
    test('ExactScore', () {
      final records = woozy.search('enim');
      // _inspectResults('enim', records);
      expect(records[0].text, startsWith('Enim id'));
      expect(records[1].text, startsWith('Consequat'));
      expect(records[2].text, startsWith('Et sunt'));
      expect(records[0].score, 1.0);
      expect(records[1].score, closeTo(0.978, 0.001));
      expect(records[2].score, closeTo(0.911, 0.001));
    });
    test('StartsWithScore', () {
      final records = woozy.search('Cons');
      // _inspectResults('Cons', records);
      expect(records[0].text, startsWith('Consequat'));
      expect(records[1].text, startsWith('Et sunt'));
      expect(records[2].text, startsWith('Enim id'));
      expect(records[0].score, closeTo(0.444, 0.001));
      expect(records[1].score, closeTo(0.383, 0.001));
      expect(records[2].score, 0.0);
    });
    test('ContainsScore', () {
      final records = woozy.search('ci');
      // _inspectResults('ci', records);
      expect(records[0].text, startsWith('Enim id'));
      expect(records[1].text, startsWith('Et sunt'));
      expect(records[2].text, startsWith('Consequat'));
      expect(records[0].score, closeTo(0.293, 0.001));
      expect(records[1].score, closeTo(0.048, 0.001));
      expect(records[2].score, 0.0);
    });
  });

  group('FirstWinsProcessor - averageScore:', () {
    Woozy woozy;
    setUp(() {
      final processor = FirstWinsProcessor(
          [ExactScore(), StartsWithScore(), ContainsScore()],
          averageScore: true);
      woozy = Woozy(processor: processor);
      woozy.addEntries([
        /**/ 'Et sunt sint deserunt ipsum do enim dolore consequat sunt sint adipisicing ipsum.',
        //                                   enim        Cons                       ci
        //                                   exact       start                      contains
        /**/ 'Consequat enim id laborum dolor sunt ut.',
        //    Cons      enim
        //    start     exact
        /**/ 'Enim id anim veniam elit duis enim id cillum aliqua irure exercitation elit magna.',
        //    Enim                          enim    ci                      ci
        //    exact                         exact   start                   contains
      ]);
    });
    test('ExactScore', () {
      final records = woozy.search('enim');
      // _inspectResults('enim', records);
      expect(records[0].text, startsWith('Consequat'));
      expect(records[1].text, startsWith('Enim id'));
      expect(records[2].text, startsWith('Et sunt'));
      expect(records[0].score, closeTo(0.978, 0.001));
      expect(records[1].score, closeTo(0.959, 0.001));
      expect(records[2].score, closeTo(0.911, 0.001));
    });
    test('StartsWithScore', () {
      // NOTE: same as the non-average, since these entries have only one match
      final records = woozy.search('Cons');
      // _inspectResults('Cons', records);
      expect(records[0].text, startsWith('Consequat'));
      expect(records[1].text, startsWith('Et sunt'));
      expect(records[2].text, startsWith('Enim id'));
      expect(records[0].score, closeTo(0.444, 0.001));
      expect(records[1].score, closeTo(0.383, 0.001));
      expect(records[2].score, 0.0);
    });
    test('ContainsScore', () {
      final records = woozy.search('ci');
      // _inspectResults('ci', records);
      expect(records[0].text, startsWith('Enim id'));
      expect(records[1].text, startsWith('Et sunt'));
      expect(records[2].text, startsWith('Consequat'));
      expect(records[0].score, closeTo(0.189, 0.001));
      expect(records[1].score, closeTo(0.048, 0.001));
      expect(records[2].score, 0.0);
    });
  });

  group('Factories:', () {
    final entries = [
      /**/ 'Et sunt sint deserunt ipsum do enim dolore consequat sunt sint adipisicing ipsum.',
      //                                                                          ci
      /**/ 'Consequat enim id laborum dolor sunt ut.',
      /**/ 'Enim id anim veniam elit duis enim id cillum aliqua irure exercitation elit magna.',
      //                                          ci                      ci
    ];
    test('esc', () {
      final woozy = Woozy.esc();
      woozy.addEntries(entries);
      final records = woozy.search('ci');
      // _inspectResults('ci', records);
      expect(records[0].text, startsWith('Enim id'));
      expect(records[1].text, startsWith('Et sunt'));
      expect(records[2].text, startsWith('Consequat'));
      expect(records[0].score, closeTo(0.293, 0.001));
      expect(records[1].score, closeTo(0.048, 0.001));
      expect(records[2].score, 0.0);
    });
    test('escFuzzy', () {
      final woozy = Woozy.escFuzzy();
      woozy.addEntries(entries);
      final records = woozy.search('ci');
      // _inspectResults('ci', records);
      expect(records[0].text, startsWith('Enim id'));
      expect(records[1].text, startsWith('Et sunt'));
      expect(records[2].text, startsWith('Consequat'));
      expect(records[0].score, closeTo(0.293, 0.001));
      expect(records[1].score, closeTo(0.048, 0.001));
      expect(records[2].score, closeTo(0.024, 0.001));
    });
  });
}

// ignore: unused_element
void _inspectResults(String query, List<MatchResult> results) {
  var lines = <String>[];
  lines.add('query: $query');
  lines.add('results:');
  results.forEach((element) {
    lines.add('  - text: ${element.text}');
    lines.add('    score: ${element.score}');
  });
  print(lines.join('\n'));
}
