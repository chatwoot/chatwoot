describe('Foundation core', function() {
  it('exists on the window', function() {
    (window.Foundation).should.be.an('object');
  });

  it('is a jQuery prototype function', function() {
    ($.fn.foundation).should.to.be.a('function');
  });

  describe('plugin()', function() {
    afterEach(function() {
      delete Foundation._plugins['plugin'];
      delete Foundation.Plugin;
    });

    it('adds Foundation plugins', function() {
      function Plugin() {}
      Foundation.plugin(Plugin, 'Plugin');

      (Foundation._plugins['plugin']).should.be.a('function');
      (Foundation.Plugin).should.be.a('function');
    });

    it('uses the name of the Plugin class/function if one is not provided', function() {
      function Plugin() {}
      Foundation.plugin(Plugin);

      (Foundation._plugins['plugin']).should.be.a('function');
      (Foundation.Plugin).should.be.a('function');
    });
  });

  describe('registerPlugin()', function() {
    it('registers a new instance of a plugin');
  });

  describe('unregisterPlugin()', function() {
    it('un-registers a plugin being destroyed');
  });

  describe('reInit()', function() {
  });

  describe('reflow()', function() {
  });

  describe('getFnName()', function() {
    it('should handle a function declaration', function() {
      function A() {};
      var name = Foundation.getFnName(A);

      name.should.be.a('string');
      name.should.be.equal('A');
    });

    it('should handle an anonymous function expression', function() {
      var name = Foundation.getFnName(function(){});

      // Inferred names (i.e. `var name = function() {}`) are not tested as they are widely supported
      // See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/name#Inferred_function_names
      name.should.be.a('string');
      name.should.be.equal('');
    });

    it('should handle a named function expression', function() {
      var D = function foo(){};
      var name = Foundation.getFnName(D);

      name.should.be.a('string');
      name.should.be.equal('foo');
    });
  });

  describe('transitionEnd()', function() {
  });

  describe('onLoad()', function (done) {
  });

  describe('throttle()', function() {
  });
});
