import 'package:collection/collection.dart';

import 'Models.dart';
import 'ScoreProcessors.dart';

/// The main entry point to the library woozy search.
class Woozy<T> {
  /// Constructor to create a `Woozy` object.
  ///
  /// If no [processor] is specified, then [defaultProcessor] is used.
  Woozy({
    this.limit = 10,
    this.caseSensitive = false,
    InputEntryProcessor processor,
    this.fallbackProcessor,
  })  : assert(limit > 0, 'limit must be greater than zero'),
        processor = processor ?? defaultProcessor;

  /// A factory function that uses [ExactScore], [StartsWithScore] and
  /// [ContainsScore] as word processors
  factory Woozy.esc({
    int limit = 10,
    bool caseSensitive = false,
    InputEntryProcessor fallbackProcessor,
  }) {
    return Woozy(
      limit: limit,
      caseSensitive: caseSensitive,
      processor: FirstWinsProcessor([
        ExactScore(),
        StartsWithScore(),
        ContainsScore(),
      ]),
      fallbackProcessor: fallbackProcessor,
    );
  }

  /// A factory function that uses the same processor as [esc], but falls back
  /// to [LevenshteinScore] (with a low weight) if the main processor yeilds a
  /// score of 0.0
  factory Woozy.escFuzzy({int limit = 10, bool caseSensitive = false}) {
    return Woozy.esc(
      limit: limit,
      caseSensitive: caseSensitive,
      fallbackProcessor: SingleScoreProcessor(LevenshteinScore(weight: 0.1)),
    );
  }

  /// The default [InputEntry] processor is computing a score, based on the
  /// Levenshtein distance from the query.
  static InputEntryProcessor get defaultProcessor =>
      SingleScoreProcessor(LevenshteinScore(), useWordIndexFalloff: false);

  /// Limit the number of items returned from a search. Defaults to 10.
  final int limit;

  /// Specify whether the string matching is case sensitive or not. Defaults
  /// to `false`.
  final bool caseSensitive;

  /// A list of items to be searched.
  List<InputEntry<T>> _entries = [];

  /// The [InputEntry] processor. Defaults to [defaultProcessor].
  final InputEntryProcessor processor;

  /// The fallback processor, in case the main returns a score of 0.0.
  final InputEntryProcessor fallbackProcessor;

  /// Add a new entry to the list of items to be searched for.
  ///
  /// [text] is where the search will be based on.
  ///
  /// [value] is an optional value that can be attached the [text].
  ///
  /// Example 1, [text] can be a description of an article, and [value] can be
  /// a database id pointing to the entire article.
  /// Example 2, [text] can be a label of an image, and [value] can the filename
  /// of the image.
  void addEntry(String text, {T value}) {
    _entries.add(InputEntry(text, value: value, caseSensitive: caseSensitive));
  }

  /// Add a list of items to be searched for.
  void addEntries(List<String> texts) {
    _entries
        .addAll(texts.map((e) => InputEntry(e, caseSensitive: caseSensitive)));
  }

  /// Set the list of items to be searched for. This will overwrite exiting
  /// items.
  void setEntries(List<String> texts) {
    _entries =
        texts.map((e) => InputEntry(e, caseSensitive: caseSensitive)).toList();
  }

  /// Given a search [query], returns a list of search results, sorted by
  /// highest score.
  List<MatchResult<T>> search(String query) {
    if (caseSensitive != true) query = query.toLowerCase();

    // Use a heap to keep track of the top `limit` best scores, sorted by score:
    // lowest first.
    var heapPQ = HeapPriorityQueue<MatchResult<T>>();

    for (final entry in _entries) {
      var score = processor.score(query, entry) ?? 0.0;

      if (score == 0.0 && fallbackProcessor != null) {
        score = fallbackProcessor.score(query, entry) ?? 0.0;
      }

      // Ensure we don't remove previous entries with the same score,
      // but keep the first-in
      if (heapPQ.length == limit && score == heapPQ.first.score) {
        continue;
      }

      heapPQ.add(MatchResult(score, text: entry.text, value: entry.value));

      if (heapPQ.length > limit) {
        heapPQ.removeFirst();
      }
    }

    // heapPQ.toList() effectively sorts the list, lowest first, so we want to
    // reverse it - highest score first.
    return heapPQ.toList().reversed.toList();
  }
}
