import PhoneNumberMatcher from '../PhoneNumberMatcher.js';
import normalizeArguments from '../normalizeArguments.js';
export default function findNumbers() {
  var _normalizeArguments = normalizeArguments(arguments),
      text = _normalizeArguments.text,
      options = _normalizeArguments.options,
      metadata = _normalizeArguments.metadata;

  var matcher = new PhoneNumberMatcher(text, options, metadata);
  var results = [];

  while (matcher.hasNext()) {
    results.push(matcher.next());
  }

  return results;
}
//# sourceMappingURL=findNumbers.js.map