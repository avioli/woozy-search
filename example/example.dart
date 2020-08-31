import 'package:woozy_search/woozy_search.dart';

void woozySearch(woozy, query) {
  final output = woozy.search(query);
  print("Search for: '$query':");
  output.forEach((element) => print(' - $element'));
  print('---\n');
}

void basicUsage() {
  final woozy = Woozy();
  woozy.addEntries(['basketball', 'badminton', 'skating']);
  woozySearch(woozy, 'badmi');
}

void withAssociatedValues() {
  final woozy = Woozy();
  woozy.addEntry('John Doe', value: '+1 210-269-0117');
  woozy.addEntry('Nate Humphrey', value: '+1 (416) 527-4927');
  woozy.addEntry('Serena Waldorf', value: '+ 1 914-514-7901');
  woozySearch(woozy, 'humphray');
}

void withSearchOutputLimit() {
  final woozy = Woozy(limit: 2);
  woozy.setEntries(List.filled(100, 'foo'));
  woozySearch(woozy, 'f');
}

void withCaseSensitive() {
  final woozy = Woozy(caseSensitive: true);
  woozy.setEntries(['FOO', 'boo']);
  woozySearch(woozy, 'foo');
}

void withEsc() {
  final loremIpsumEntries = [
    'Et sunt sint deserunt ipsum do enim dolore consequat sunt sint adipisicing ipsum.',
    'Consequat enim id laborum dolor sunt ut.',
    'Enim id anim veniam elit duis enim id cillum aliqua irure exercitation elit magna.',
  ];

  var query = 'ci';

  var woozy = Woozy();
  woozy.setEntries(loremIpsumEntries);
  print('Standard Levenshtein distance:');
  woozySearch(woozy, query);

  woozy = Woozy.esc();
  print('With Exact/StartsWith/Contains processors:');
  woozy.setEntries(loremIpsumEntries);
  woozySearch(woozy, query);

  woozy = Woozy.escFuzzy();
  print(
      'With Exact/StartsWith/Contains processors, and fallback to Levenshein:');
  woozy.setEntries(loremIpsumEntries);
  woozySearch(woozy, query);
}

void main() {
  basicUsage();

  withAssociatedValues();

  withSearchOutputLimit();

  withCaseSensitive();

  withEsc();
}
