import _isPossiblePhoneNumber from './isPossiblePhoneNumber.js';
import metadata from '../metadata.min.json' assert { type: 'json' };
import oldMetadata from '../test/metadata/1.0.0/metadata.min.json' assert { type: 'json' };

function isPossiblePhoneNumber() {
  for (var _len = arguments.length, parameters = new Array(_len), _key = 0; _key < _len; _key++) {
    parameters[_key] = arguments[_key];
  }

  parameters.push(metadata);
  return _isPossiblePhoneNumber.apply(this, parameters);
}

describe('isPossiblePhoneNumber', function () {
  it('should detect whether a phone number is possible', function () {
    isPossiblePhoneNumber('8 (800) 555 35 35', 'RU').should.equal(true);
    isPossiblePhoneNumber('8 (800) 555 35 35 0', 'RU').should.equal(false);
    isPossiblePhoneNumber('Call: 8 (800) 555 35 35', 'RU').should.equal(false);
    isPossiblePhoneNumber('8 (800) 555 35 35', {
      defaultCountry: 'RU'
    }).should.equal(true);
    isPossiblePhoneNumber('+7 (800) 555 35 35').should.equal(true);
    isPossiblePhoneNumber('+7 1 (800) 555 35 35').should.equal(false);
    isPossiblePhoneNumber(' +7 (800) 555 35 35').should.equal(false);
    isPossiblePhoneNumber(' ').should.equal(false);
  });
  it('should detect whether a phone number is possible when using old metadata', function () {
    expect(function () {
      return _isPossiblePhoneNumber('8 (800) 555 35 35', 'RU', oldMetadata);
    }).to["throw"]('Missing "possibleLengths" in metadata.');

    _isPossiblePhoneNumber('+888 123 456 78901', oldMetadata).should.equal(true);
  });
});
//# sourceMappingURL=isPossiblePhoneNumber.test.js.map