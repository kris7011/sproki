import 'package:flutter_test/flutter_test.dart';
import 'package:sproki/features/speech_practice/domain/word_matcher.dart';

void main() {
  const matcher = WordMatcher();

  test('matches exact Danish words regardless of case or punctuation', () {
    expect(matcher.matches('  ÆBLE!  ', 'æble'), isTrue);
    expect(matcher.matches('Jeg siger øre.', 'øre'), isTrue);
    expect(matcher.matches('blå bil', 'blå bil'), isTrue);
  });

  test('does not treat unrelated substrings as recognized words', () {
    expect(matcher.matches('random', 'and'), isFalse);
    expect(matcher.matches('Hestene', 'hest'), isFalse);
    expect(matcher.matches('et æbletræ', 'æble'), isFalse);
    expect(matcher.matches('', 'and'), isFalse);
  });

  test('matches phrases only as consecutive whole words', () {
    expect(matcher.matches('min blå bil er her', 'blå bil'), isTrue);
    expect(matcher.matches('blå stor bil', 'blå bil'), isFalse);
  });
}
