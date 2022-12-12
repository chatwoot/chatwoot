describe('Foundation core utils', function() {

  describe('rtl()', function() {
    it('detects the text direction on the document', function() {
      (Foundation.rtl()).should.be.false;
      $('html').attr('dir', 'rtl');

      (Foundation.rtl()).should.be.true;
      $('html').attr('dir', 'ltr');
    });
  });

  describe('GetYoDigits()', function() {
    it('generates a random ID matching a given length', function() {
      var id = Foundation.GetYoDigits(6);

      id.should.be.a('string');
      id.should.have.lengthOf(6);
    });

    it('can append a namespace to the number', function() {
      var id = Foundation.GetYoDigits(6, 'plugin');

      id.should.be.a('string');
      id.should.have.lengthOf(6 + '-plugin'.length);
      id.should.contain('-plugin');
    });
  });

  describe('RegExpEscape()', function() {
    it('escape all special characters in a string for RegExp', function () {
      const str = 'abc012-[]{}()*+?.,\\^$|#\s\t\r\n';
      const notstr = 'abc012-[]{}not-the-escaped-string';
      const reg = new RegExp(Foundation.RegExpEscape(str), 'g');

      reg.test(str).should.be.true;
      reg.test(notstr).should.be.false;
    });
  });

});
