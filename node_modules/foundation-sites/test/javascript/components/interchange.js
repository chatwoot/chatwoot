describe('Interchange', function () {
  var plugin;
  var $html;

  /**
   * Generates paths to different assets
   * @param  {[type]} type [description]
   * @param  {[type]} size [description]
   * @return {[type]}      [description]
   */
  var getPath = function(type, size) {
    switch (type) {
      case 'image':
      case 'background':
        return `_build/assets/img/interchange/strip_icc()/${size}.jpg`;
      default:
        return `_build/assets/partials/interchange-${size}.html`;
    }
  };
  /**
   * Generates templates to use based on type.
   * @param  {string} type Type to generate, image, background or template.
   * @return {string}      Generated template.
   */
  var generateTemplate = function(type) {
    var type = type || 'template',
        tag = type === 'image' ? 'img' : 'div',
        path;
    switch (type) {
      case 'image':
        return `<img data-interchange="
            [${getPath(type, 'small')}, small],
            [${getPath(type, 'medium')}, medium],
            [${getPath(type, 'large')}, large]
          ">`;
      case 'background':
        return `<div data-interchange="
            [${getPath(type, 'small')}, small],
            [${getPath(type, 'medium')}, medium],
            [${getPath(type, 'large')}, large]
          "></div>`;
      default:
        return `<div data-interchange="
            [${getPath(type, 'default')}, small],
            [${getPath(type, 'medium')}, medium],
            [${getPath(type, 'large')}, large]
          "></div>`;
    }
  };

  afterEach(function() {
    plugin.destroy();
    $html.remove();
  });

  describe('constructor()', function() {
    it('stores the element and plugin options', function() {
      $html = $(generateTemplate('template')).appendTo('body');
      plugin = new Foundation.Interchange($html, {});

      plugin.$element.should.be.an('object');
      plugin.options.should.be.an('object');
    });
  });

  describe('replace()', function() {
    it('replaces src attribute of img', function() {
      $html = $(generateTemplate('image')).attr('data-interchange', '').appendTo('body');
      plugin = new Foundation.Interchange($html, {});

      plugin.replace(getPath('img', 'large'));

      $html.should.have.attr('src', getPath('img', 'large'));
    });

    it('replaces background style of divs', function() {
      $html = $(generateTemplate('background')).attr('data-interchange', '').appendTo('body');
      plugin = new Foundation.Interchange($html, {});

      plugin.replace(getPath('background', 'large'));

      $html[0].style.backgroundImage.should.contain(getPath('background', 'large').replace(/\(/g, '%28').replace(/\)/g, '%29'));
    });

    it('replaces contents of div with templates', function() {
      $html = $(generateTemplate('template')).attr('data-interchange', '').appendTo('body');
      plugin = new Foundation.Interchange($html, {});

      var spy = sinon.spy($, 'get');

      plugin.replace(getPath('template', 'large'));

      sinon.assert.calledWith(spy, getPath('template', 'large'));

      spy.restore();
    });

    it('fires replaced.zf.interchange event', function() {
      $html = $(generateTemplate('image')).appendTo('body');
      plugin = new Foundation.Interchange($html, {});

      let spy = sinon.spy();
      $html.on('replaced.zf.interchange', spy);

      plugin.replace(getPath('image', 'large'));

      sinon.assert.called(spy);
    });
  });

  describe('reflow()', function() {
    it('calls replace for given media query', function() {
      $html = $(generateTemplate('image')).attr('data-interchange', '[image.png, (min-width: 1px)]').appendTo('body');
      plugin = new Foundation.Interchange($html, {});

      let spy = sinon.spy();
      plugin.replace = spy;

      plugin._reflow();

      sinon.assert.calledWith(spy, 'image.png');
    });
  });

  describe('generateRules()', function() {
    it('extracts rules from the plugin element', function() {
      $html = $(generateTemplate('image')).appendTo('body');
      plugin = new Foundation.Interchange($html, {});

      plugin._generateRules($html);

      plugin.rules.length.should.be.equal(3);
    });

    it('extracts special queries from the plugin element', function() {
      $html = $(generateTemplate('image')).attr('data-interchange', '[image.png, retina]').appendTo('body');
      plugin = new Foundation.Interchange($html, {});

      plugin._generateRules($html);

      plugin.rules[0].query.should.be.equal(Foundation.Interchange.SPECIAL_QUERIES['retina']);
    });
  });


  describe('addBreakpoints()', function() {
    it('adds Foundation breakpoints to special queries', function() {
      $html = $(generateTemplate('image')).appendTo('body');
      plugin = new Foundation.Interchange($html, {});


      var specialQueriesCount = Object.keys(Foundation.Interchange.SPECIAL_QUERIES).length,
          foundationMediaQueriesCount = Foundation.MediaQuery.queries.length;

      Foundation.MediaQuery.queries.push({
        name: 'test-query',
        value: 'test-query-value'
      })

      plugin._addBreakpoints($html);

      Object.keys(Foundation.Interchange.SPECIAL_QUERIES).length.should.be.equal(specialQueriesCount + 1);

      // Reset Foundation.MediaQueries
      Foundation.MediaQuery.queries.length = foundationMediaQueriesCount;
    });
  });

  describe('events()', function () {
    it('calls reflow on viewport size change once', function (done) {
      $html = $(generateTemplate('image')).appendTo('body');
      plugin = new Foundation.Interchange($html, {});

      // Debounce: time Triggers is waiting for an other event without firing anything (10 by default)
      const debounce = 10;
      // Initialize Triggers manually to control and test the debounce time
      Foundation.Triggers.Initializers.addMutationEventsListener($(document));
      Foundation.Triggers.Initializers.addResizeListener(debounce);
      $.triggersInitialized = true;

      // Trigger several window resize synchrnously and asynchronously.
      // ---
      // Timeout delays are most often not respected and the differences between several
      // timeouts running in parrallel can be huge. To prevent race conditions we:
      // * nest timeout in order to make the delay between them more precise
      // * run the test several time to wait for the debounce, which may be finally
      //   called way after the expected time.
      setTimeout(function () {
        let spy = sinon.spy(plugin, '_reflow');
        $(window).trigger('resize');
        $(window).trigger('resize');

        setTimeout(function () {
          $(window).trigger('resize');
          $(window).trigger('resize');

          tryInterval({
            interval: debounce,
            timeout: 1000,
            try: () => {
              sinon.assert.calledOnce(spy);
            },
            then: () => {
              $.triggersInitialized = false;
              done();
            },
          });

        });
      });
    });
  });

});
