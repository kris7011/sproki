/// Matches a complete Danish word or phrase, never an unrelated substring.
/// This is a text comparison, not a clinical assessment of pronunciation.
class WordMatcher {
  const WordMatcher();

  static final RegExp _separator = RegExp(r'[^a-z0-9æøå]+');

  bool matches(String recognized, String target) {
    final spoken = _tokens(recognized);
    final expected = _tokens(target);
    if (expected.isEmpty || spoken.length < expected.length) return false;

    for (var start = 0; start <= spoken.length - expected.length; start++) {
      var equal = true;
      for (var i = 0; i < expected.length; i++) {
        if (spoken[start + i] != expected[i]) {
          equal = false;
          break;
        }
      }
      if (equal) return true;
    }
    return false;
  }

  List<String> _tokens(String input) => input
      .toLowerCase()
      .trim()
      .split(_separator)
      .where((token) => token.isNotEmpty)
      .toList(growable: false);
}
