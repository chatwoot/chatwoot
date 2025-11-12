"use strict";

var _RFC = require("./RFC3966.js");

describe('RFC3966', function () {
  it('should format', function () {
    expect(function () {
      return (0, _RFC.formatRFC3966)({
        number: '123'
      });
    }).to["throw"]('expects "number" to be in E.164 format');
    (0, _RFC.formatRFC3966)({}).should.equal('');
    (0, _RFC.formatRFC3966)({
      number: '+78005553535'
    }).should.equal('tel:+78005553535');
    (0, _RFC.formatRFC3966)({
      number: '+78005553535',
      ext: '123'
    }).should.equal('tel:+78005553535;ext=123');
  });
  it('should parse', function () {
    (0, _RFC.parseRFC3966)('tel:+78005553535').should.deep.equal({
      number: '+78005553535'
    });
    (0, _RFC.parseRFC3966)('tel:+78005553535;ext=123').should.deep.equal({
      number: '+78005553535',
      ext: '123'
    }); // With `phone-context`

    (0, _RFC.parseRFC3966)('tel:8005553535;ext=123;phone-context=+7').should.deep.equal({
      number: '+78005553535',
      ext: '123'
    }); // "Domain contexts" are ignored

    (0, _RFC.parseRFC3966)('tel:8005553535;ext=123;phone-context=www.leningrad.spb.ru').should.deep.equal({
      number: '8005553535',
      ext: '123'
    }); // Not a viable phone number.

    (0, _RFC.parseRFC3966)('tel:3').should.deep.equal({});
  });
});
//# sourceMappingURL=RFC3966.test.js.map