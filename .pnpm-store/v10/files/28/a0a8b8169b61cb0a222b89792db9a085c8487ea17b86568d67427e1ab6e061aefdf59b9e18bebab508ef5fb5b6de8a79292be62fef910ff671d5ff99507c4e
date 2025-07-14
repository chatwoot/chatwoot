
describe('obj-case', function () {

  var expect  = require('expect.js')
    , objCase = require('..');

  describe('.find()', function () {
    it('should be a function', function () {
      expect(objCase.find).to.be.a.Function;
    });

    it('should be the main export', function () {
      expect(objCase.find).to.be(objCase);
    });

    it('should find simple keys', function () {
      expect(objCase({ a : 'b' }, 'a')).to.eql('b');
      expect(objCase({ first_name : 'Calvin' }, 'firstName')).to.eql('Calvin');
      expect(objCase({ 'first name' : 'Calvin' }, 'first_name')).to.eql('Calvin');
    });

    it('should find nested keys', function () {
      expect(objCase({ a : { b : { c : 'd' }}}, 'a.b.c')).to.eql('d');
      expect(objCase({ 'A bird': { flew_under: { theTrain: 4 } } }, 'a bird.flew_under.the_train')).to.eql(4);
    });

    it('should find falsey keys', function () {
      expect(objCase({ a : { b : false }}, 'a.b')).to.eql(false);
      expect(objCase({ a : { b : 0 }}, 'a.b')).to.eql(0);
    });

    it('should find non-uniform cased keys', function () {
      expect(objCase({ camel_Case: true }, 'camel_Case')).to.eql(true);
    });

    it('should find dot-separated paths as object key', function () {
      var obj = { 'a.b': 10 };
      expect(objCase(obj, 'a.b')).to.eql(10);
    });

    it('should find dot-separated paths in a nested object', function () {
      var obj = { a: { 'b.c': 10 } };
      expect(objCase(obj, 'a.b.c')).to.eql(10);
    });

    it('should work on blank objects', function () {
      var obj = {};
      expect(objCase(obj, 'a.b.c')).to.eql(undefined);
    });

    it('should work with properties with same prefix', function () {
      var obj3 = {
        website: {
          left: 'aaaa'
        },
        websites: {
          right: 'bbbb'
        }
      };
      expect(objCase(obj3, 'website.left')).to.eql('aaaa');
      expect(objCase(obj3, 'websites.right')).to.eql('bbbb');

      var obj1 = {
        website: 'aaaa',
        websites: 'bbbb'
      };
      expect(objCase(obj1, 'website')).to.eql('aaaa');
      expect(objCase(obj1, 'websites')).to.eql('bbbb');

      var obj2 = {
        websites: 'bbbb',
        website: 'aaaa'
      };
      expect(objCase(obj2, 'website')).to.eql('aaaa');
      expect(objCase(obj2, 'websites')).to.eql('bbbb');

      var obj4 = {
        websites: 'bbbb'
      };
      expect(objCase(obj4, 'website')).to.eql(undefined);
      expect(objCase(obj4, 'websites')).to.eql('bbbb');
    });

    it('should work with a terminal value of null', function(){
      var obj = { traits: { email: null } };
      expect(objCase(obj, 'traits.email')).to.eql(null)
    });

    it('should work with a terminal value of undefined', function(){
      var obj = { traits: { email: undefined } };
      expect(objCase(obj, 'traits.email')).to.eql(undefined)
    });

    describe('casing', function(){
      it('should find crazy looking paths', function () {
        var obj = { a: { 'HelloWorld.BAR': 10 } };
        expect(objCase(obj, 'A.HELLO_WORLD.bar')).to.eql(10);
      });

      it('should find crazy looking paths 2', function () {
        var obj = { 'HELLO_WORLD.a.B': 10 };
        expect(objCase(obj, 'helloWorld.a.B')).to.eql(10);
      });

      it('should treat camel-cased same as lowercase', function () {
        var obj = { 'woodyallen': 10 };
        expect(objCase(obj, 'woodyAllen')).to.eql(10);
      });

      it('should find crazy looking paths 3', function () {
        var obj = { 'some-crazy.PROBABLY_POSSIBLE.NestedProperty': 10 };
        expect(objCase(obj, 'SOME_CRAZY.ProbablyPossible.nested_property')).to.eql(10);
      });

      it('should return undefined if it doesnt find a match', function () {
        var obj = { 'some-crazy.PROBABLY_MISSPELLED.NestedProperty': 10 };
        expect(objCase(obj, 'SOME_CRAZY.ProbablyMssplld.nested_property')).to.eql(undefined);
      });
    });
  });

  describe('.del()', function () {
    it('should delete simple keys', function () {
      var obj = { firstName : 'Calvin', lastName : 'French-Owen' };
      expect(objCase.del(obj, 'first name')).to.eql({ lastName: 'French-Owen' });
    });

    it('should delete nested keys', function () {
      expect(objCase.del({ 'A bird' : { 'flew_under' : { 'theTrain' : 4 }}}, 'aBird.FLEW UNDER')).to.eql({ 'A bird': {} });
    });

    it('should accept a custom key normalizer', function () {
      var obj = { one: { a: { b: 'nested' } }, two: 'two' };
      var normalize = function(path) {
        return path.replace(/[x]/g, '');
      };
      var options = { normalizer: normalize };
      var expected = {
        one: { a: {} },
        two: 'two'
      };

      expect(objCase.del(obj, 'xxonxe.xa.xxbxx', options)).to.eql(expected);
    });
  });

  describe('.replace()', function () {
    it('should replace simple keys', function () {
      var obj = { firstName : 'Calvin', lastName : 'French-Owen' };
      expect(objCase.replace(obj, 'last name', 'Harris')).to.eql({
        firstName : 'Calvin',
        lastName  : 'Harris'
      });
    });

    it('should replace nested keys', function () {
      var obj = { "Calvin" : { dog : 'teddy' }};
      expect(objCase.replace(obj, "Calvin.dog", 'the tedster')).to.eql({
        "Calvin" : { dog : 'the tedster' }
      });
    });

    it('should accept a custom key normalizer', function () {
      var obj = { one: { a: { b: 'nested' } }, two: 'two' };
      var normalize = function(path) {
        return path.replace(/[x]/g, '');
      };
      var options = { normalizer: normalize };
      var expected = {
        one: { a: { b: 'newvalue' } },
        two: 'two'
      };

      expect(objCase.replace(obj, 'xxonxe.xa.xxbxx', 'newvalue', options)).to.eql(expected);
    });
  });

  describe('performance', function(){
    it('should be performant', function(){
      var obj = { 'A bird': { flew_under: { theTrain: 4 } } };
      for (var i = 0, n = 100000; i < n; i++) {
        objCase(obj, 'a bird.flew_under.the_train');
      }
    });
  });
});
