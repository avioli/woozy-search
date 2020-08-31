# Woozy Search

A super simple and lightweight client-side fuzzy-search library based on Levenshtein distance. 

## Usage

```pubspec.yaml
dependencies:
  woozy_search: '>=2.0.0 <3.0.0'
```

**Basic Usage**

```dart
import 'package:woozy_search/woozy_search.dart';

main() {
  final woozy = Woozy();
  woozy.addEntries(['basketball', 'badminton', 'skating']);
  final output = woozy.search('badmi');
  output.forEach((element) => print(' - ${element}'));
}
```

Output:

```text
 - text: badminton, score: 0.56
 - text: basketball, score: 0.20
 - text: skating, score: 0.14
```

**With Associate Values**

Associate value can be anything, integers, UUIDs, text, etc. 
As an example, we use a name and their phone number here. 

```dart
import 'package:woozy_search/woozy_search.dart';

main() {
  final woozy = new Woozy();
  woozy.addEntry('John Doe', value: "+1 210-269-0117");
  woozy.addEntry('Nate Humphrey', value: "+1 (416) 527-4927");
  woozy.addEntry('Serena Waldorf', value: "+ 1 914-514-7901");
  final output = woozy.search('humphray');
  output.forEach((element) => print(' - ${element}'));
}
```

Output:

```text
 - text: Nate Humphrey, score: 0.88, value: +1 (416) 527-4927
 - text: Serena Waldorf, score: 0.13, value: + 1 914-514-7901
 - text: John Doe, score: 0.13, value: +1 210-269-0117
```

**With Search Output Limit**

Limit the number of search result to return.
It is defaulted to 10, but can be overwritten. 

```dart
import 'package:woozy_search/woozy_search.dart';
  
main() {
  final woozy = Woozy(limit: 2);
  woozy.setEntries(List.filled(100, 'foo'));
  final output = woozy.search('f');
  output.forEach((element) => print(' - ${element}'));
}
```

Output:

```text
 - text: foo, score: 0.33
 - text: foo, score: 0.33
```

**With Case Sensitive**

```dart
main() {
  final woozy = Woozy(caseSensitive: true);
  woozy.setEntries(['FOO', 'boo']);
  final output = woozy.search('foo');
  output.forEach((element) => print(' - ${element}'));
}
```

Output:

```text
 - text: boo, score: 0.67
 - text: FOO, score: 0.00
```

## Using custom input-entry processor

*This is more advanced configuration*, so it is highly advisable to use the
built-in factories, which we discuss [further down](#using-the-built-in-factories).

You can use a custom input-entry processor by settings the `processor` named
parameter. It defaults to using the Levenshtein distance only as word-scoring
mechanism.

An input-entry processor could use one or more word-scoring processors, which
score each word from every entry to build the overall score.

There are four ready-to-use word processors:

  - `LevenshteinScore` - uses the Levenshtein distance between the query and
    each word of the input-entry
  - `ExactScore` - uses a simple `==` predicate
  - `StartsWithScore` - uses `String.startsWith` predicate, but returns a score,
    based on the width of the query, compared to the length of the entry word
  - `ContainsScore` - similar to `StartsWithScore`, but matches entries within
    the entry word. The position of the match further affects the score.

If using multiple word processors, then how each word processor's score affects
the final score is determined by an input-entry processor.

There are two such built-in processors:

  - `FirstWinsProcessor` - picks the first word processor that returns a
    non-zero score. It uses a word-index falloff scoring so a match in the
    beginning of the entry text will have a higher score, than a match towards
    the end
  - `SingleScoreProcessor` - a helper wrapper around FirstWinsProcessor,
    that uses a single word processor

```dart
var wordProcessors = [ExactScore(), LevensteinScore(weight: 0.5)];
var proc = FirstWinsProcessor(wordProcessors);
final woozy = Woozy(processor: proc);
```

You can specify a `fallbackProcessor` to use if the score for an entry ends up
zero:

```dart
final woozy = Woozy(
  processor: FirstWinsProcessor([
    ExactScore(),
    StartsWithScore(),
    ContainsScore(),
  ]),
  fallbackProcessor: SingleScoreProcessor(LevenshteinScore(weight: 0.1),
);
```

Feel free to implement your own `InputEntryProcessor` or `WordScoreProcessor`.

Since these configurations above are a good default there are two factories that
produce them.


### Using the built-in factories

  - `Woozy.esc()` - uses the Exact/StartsWith/Contains scoring (in that order)
  - `Woozy.escFuzzy()` - same as `esc`, but uses the Levenshtein word processor
    as fallabck with a weight of `0.1`

```dart
main() {
  final woozy = Woozy.escFuzzy();
  final loremIpsumEntries = [
    'Et sunt sint deserunt ipsum do enim dolore consequat sunt sint adipisicing ipsum.',
    'Consequat enim id laborum dolor sunt ut.',
    'Enim id anim veniam elit duis enim id cillum aliqua irure exercitation elit magna.',
  ];
  woozy.setEntries(loremIpsumEntries);
  final output = woozy.search('ci');
  output.forEach((element) => print(' - ${element}'));
}
```

Output:

```text
 - text: Enim id anim veniam elit duis enim id cillum aliqua irure exercitation elit magna., score: 0.29
 - text: Et sunt sint deserunt ipsum do enim dolore consequat sunt sint adipisicing ipsum., score: 0.05
 - text: Consequat enim id laborum dolor sunt ut., score: 0.02
```

If we used `Woozy.esc()` instead the last result would have had a score of
`0.0`, since it doesn't contain the query anywhere.


## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/IvoriApp/woozy-search/issues


### Running the tests

```sh
pub run test
```
