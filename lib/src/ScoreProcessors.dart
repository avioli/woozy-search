import 'dart:math';

import 'Models.dart';
import 'Levenshtein.dart';

// /////////////////////////////////////////////////////////////////////////////
// InputEntry Score Processors
// /////////////////////////////////////////////////////////////////////////////

/// An [InputEntry] processor, which takes the first non-zero
/// [WordScoreProcessor] score
///
/// The [query] is expected to be a single word.
///
/// ```
/// var processors = [ExactScore(), StartsWithScore(), ContainsScore()];
/// var proc = FirstWinsProcessor(processors);
/// var entry = InputEntry('Woozy is great', caseSensitive: false);
/// // ExactScore wins (on first word):
/// assert(proc.score('woozy', entry) == 1.0);
/// // StartsWith wins (on last word):
/// assert((proc.score('gre', entry) * 1000).round() == 505);
/// // ContainsScore wins (on last word):
/// assert((proc.score('eat', entry) * 1000).round() == 303);
/// ```
///
/// If [averageScore] is `false` - the default, then the best score will be used
/// from any matched words. Otherwise - the average of all _matched_ words.
///
/// ```
/// var avg = FirstWinsProcessor(processors, averageScore: true);
/// entry = InputEntry('eat great seat treat', caseSensitive: false);
/// // default:
/// assert(proc.score('eat', entry) == 1.0);
/// // average:
/// assert((avg.score('eat', entry) * 1000).round() == 534);
/// ```
///
/// When processing multiple words, the expected default, each word gets a
/// weight multiplier applied to it, based on the processor's weight parameter
/// and the index of the word. So words towards the end of the input entry
/// will get lower score.
class FirstWinsProcessor implements InputEntryProcessor {
  FirstWinsProcessor(
    this.wordProcessors, {
    this.useWordIndexFalloff = true,
    this.averageScore = false,
  })  : assert(useWordIndexFalloff != null),
        assert(averageScore != null);

  final List<WordScoreProcessor> wordProcessors;

  final bool useWordIndexFalloff;
  final bool averageScore;

  @override
  double score(String query, InputEntry entry) {
    var score = 0.0;
    var matchedWords = 0;
    var words = entry.words;
    var count = words.length;
    var logTable = useWordIndexFalloff ? _buildLog2Table(count) : null;

    bool _calcScore(WordScoreProcessor processor, int index) {
      var wordScore = processor.score(query, words[index]) ?? 0.0;
      if (useWordIndexFalloff) {
        // Apply word index weight multiplier
        wordScore *= logTable[index];
      }
      if (wordScore > 0.0) {
        matchedWords++;
        if (averageScore) {
          score += wordScore;
        } else {
          score = max(score, wordScore);
        }
        return true;
      }
      return false;
    }

    for (var index = 0; index < count; index++) {
      for (final processor in wordProcessors) {
        if (_calcScore(processor, index)) {
          break;
        }
      }
    }

    if (matchedWords == 0) {
      return 0.0;
    }

    return averageScore ? score / matchedWords : score;
  }
}

// /////////////////////////////////////////////////////////////////////////////

/// An [InputEntry] processor, which takes a single word processor
class SingleScoreProcessor extends FirstWinsProcessor {
  SingleScoreProcessor(
    WordScoreProcessor wordProcessor, {
    bool useWordIndexFalloff = true,
    bool averageScore = false,
  })  : assert(wordProcessor != null),
        super([wordProcessor],
            useWordIndexFalloff: useWordIndexFalloff,
            averageScore: averageScore);
}

// /////////////////////////////////////////////////////////////////////////////
// Word Score Processors
// /////////////////////////////////////////////////////////////////////////////

/// Produces a score, based on Levenshtein distance between a given [query]
/// and [word]
///
/// The score will be between `0.0` - `1.0`. Higher means better match.
///
/// A `null` score will be produced if query and word are empty.
class LevenshteinScore implements WordScoreProcessor {
  LevenshteinScore({this.weight = 1.0});

  final _levenshtein = Levenshtein();

  @override
  final double weight;

  @override
  double score(String word1, String word2) {
    final maxLength = max(word1.length, word2.length);
    if (maxLength == 0) return null;
    final _distance = _levenshtein.distance(word1, word2);
    return (maxLength - _distance) / maxLength * weight;
  }
}

// /////////////////////////////////////////////////////////////////////////////

/// Produces a score of `1.0` when [query] and [word] exactly match
///
/// `0.0` score is given when the word doesn't exactly match the given query.
///
/// The positive match score value can be adjusted with [value].
///
/// A `null` score will be produced if either query or word are empty.
class ExactScore implements WordScoreProcessor {
  const ExactScore({this.weight = 1.0}) : assert(weight != null);

  @override
  final double weight;

  @override
  double score(String query, String word) {
    if (word.isEmpty || query.isEmpty) return null;
    if (word == query) {
      return weight;
    }
    return 0.0;
  }
}

// /////////////////////////////////////////////////////////////////////////////

/// Produces a score matching [query] at the beginning of a given [word]
///
/// The score will be between `0.01` - `1.0` (with default multiplier), based
/// on the length of the match, compared to the length of the word.
///
/// `0.0` score is given when the word doesn't start with given query.
///
/// A `null` score will be produced if either query or word are empty.
///
/// For example:
///
/// `score('a', 'a-long-string') == 0.0769...` since 'a' is about 8% of the
/// whole length.
///
/// `score('a-long', 'a-long-string') = 0.462...` since it is 46% of the whole
/// length.
class StartsWithScore implements WordScoreProcessor {
  const StartsWithScore({this.weight = 1.0}) : assert(weight != null);

  @override
  final double weight;

  @override
  double score(String query, String word) {
    if (word.isEmpty || query.isEmpty) return null;
    if (word.startsWith(query)) {
      return query.length / word.length * weight;
    }
    return 0.0;
  }
}

// /////////////////////////////////////////////////////////////////////////////

/// Produces a score matching [query] at within a given [word]
///
/// The score will be between `0.01` - `1.0` (with default multiplier), based
/// on the position and length of the match, compared to the length of the word.
///
/// `0.0` score is given when the word doesn't contain given query.
///
/// A `null` score will be produced if either query or word are empty.
///
/// For example:
///
/// `score('t', 'a-long-string') == 0.0296...` since 't' is in the middle and
/// is just 8% of the whole length.
///
/// `score('s', 'a-long-string') == 0.0355...` since 's' is closer to the
/// beginning.
///
/// `score('long', 'a-long-string') = 0.26...` since 'long' is closer to the
/// beginning and is whole 30% of the whole length.
///
/// `score('a-long', 'a-long-string') = 0.462...` which is similar to what
/// [StartsScore] produces.
class ContainsScore implements WordScoreProcessor {
  const ContainsScore({this.weight = 1.0}) : assert(weight != null);

  @override
  final double weight;

  @override
  double score(String query, String word) {
    if (word.isEmpty || query.isEmpty) return null;
    final index = word.indexOf(query);
    if (index != -1) {
      final queryScore = query.length / word.length;
      final indexScore = (word.length - index) / word.length;
      return queryScore * indexScore * weight;
    }
    return 0.0;
  }
}

/// Compute a log2 table for word-index fall-off
///
/// For example:
///
/// Given count of 13:
/// ```
/// [1.0,
///  0.988, 0.976, 0.962, 0.947, 0.93, 0.91,
///  0.888, 0.862, 0.83,
///  0.788, 0.73,
///  0.63]
/// ```
List<double> _buildLog2Table(int count) {
  assert(count > 0);
  var coef = 1024 / count;
  return List<double>.generate(
      count, (idx) => log((count - idx) * coef) * log2e / 10);
}
