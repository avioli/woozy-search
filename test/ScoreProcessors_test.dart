import 'package:woozy_search/woozy_search.dart';
import 'package:woozy_search/src/Models.dart';
import 'package:test/test.dart';

void main() {
  group('LevenshteinScore:', () {
    final processor = LevenshteinScore();
    test('1.0 score', () {
      expect(processor.score('exact', 'exact'), 1);
    });
    test('null score', () {
      expect(processor.score('', ''), null);
    });
    test('mid score', () {
      expect(processor.score('HONDA', 'HYUNDAI'), closeTo(0.571, 0.001));
      expect(processor.score('t', 'a-long-string'), closeTo(0, 0.1));
    });
    test('0.0 score', () {
      expect(processor.score('right-empty', ''), 0);
      expect(processor.score('', 'left-empty'), 0);
      expect(processor.score('no', 'match'), 0);
    });
  });

  group('ExactScore:', () {
    final processor = ExactScore();
    test('1.0 score', () {
      expect(processor.score('exact', 'exact'), 1);
    });
    test('null score', () {
      expect(processor.score('', ''), null);
      expect(processor.score('right-empty', ''), null);
      expect(processor.score('', 'left-empty'), null);
    });
    test('0.0 score', () {
      expect(processor.score('no', 'match'), 0);
      expect(processor.score('HONDA', 'HYUNDAI'), 0);
      expect(processor.score('t', 'a-long-string'), 0);
    });
  });

  group('StartsWithScore:', () {
    final processor = StartsWithScore();
    test('1.0 score', () {
      expect(processor.score('exact', 'exact'), 1);
    });
    test('null score', () {
      expect(processor.score('', ''), null);
      expect(processor.score('right-empty', ''), null);
      expect(processor.score('', 'left-empty'), null);
    });
    test('mid score', () {
      expect(processor.score('fun', 'funny'), 0.6);
    });
    test('0.0 score', () {
      expect(processor.score('no', 'match'), 0);
      expect(processor.score('HONDA', 'HYUNDAI'), 0);
      expect(processor.score('t', 'a-long-string'), 0);
      expect(processor.score('un', 'funny'), 0.0);
      expect(processor.score('ny', 'funny'), 0.0);
    });
  });

  group('ContainsScore:', () {
    final processor = ContainsScore();
    test('1.0 score', () {
      expect(processor.score('exact', 'exact'), 1);
    });
    test('null score', () {
      expect(processor.score('', ''), null);
      expect(processor.score('right-empty', ''), null);
      expect(processor.score('', 'left-empty'), null);
    });
    test('mid score', () {
      expect(processor.score('t', 'a-long-string'), closeTo(0, 0.1));
      expect(processor.score('fun', 'funny'), 0.6);
      expect(processor.score('un', 'funny'), closeTo(0.32, 0.01));
      expect(processor.score('ny', 'funny'), closeTo(0.16, 0.01));
    });
    test('0.0 score', () {
      expect(processor.score('no', 'match'), 0);
      expect(processor.score('HONDA', 'HYUNDAI'), 0);
    });
  });

  group('FirstWinsProcessor', () {
    var processors = [ExactScore(), StartsWithScore(), ContainsScore()];
    var entry = InputEntry('Woozy is great', caseSensitive: false);

    test('Example 1', () {
      var proc = FirstWinsProcessor(processors);
      expect(proc.score('woozy', entry), 1.0);
      // StartsWith wins (on last word):
      expect(proc.score('gre', entry), closeTo(0.505, 0.001));
      // ContainsScore wins (on last word):
      expect(proc.score('eat', entry), closeTo(0.303, 0.001));
    });
    test('Example 1 - average score', () {
      var avg = FirstWinsProcessor(processors, averageScore: true);
      // eat: 1.0, great: 0.38, seat: 0.39, treat: 0.29
      entry = InputEntry('eat great seat treat', caseSensitive: false);
      // average:
      expect(avg.score('eat', entry), closeTo(0.534, 0.001));
    });
  });
}
