describe('Slider', function() {
  var plugin;
  var $html;
  var template = `<div class="slider" data-slider>
      <span class="slider-handle" data-slider-handle role="slider" tabindex="1"></span>
      <span class="slider-fill" data-slider-fill></span>
      <input type="hidden">
    </div>`;

  Foundation.Slider.defaults.moveTime = 0;
  Foundation.Slider.defaults.changedDelay = 0;

  afterEach(function(done) {
    // Timeout needed because even with changeDelay = 0 the changed.zf.slider event may be fired after this hook
    plugin.destroy();
    $html.remove();
    done();
  });

  describe('constructor()', function() {
    it('stores the element and plugin options', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Slider($html, {});

      plugin.$element.should.be.an('object');
      plugin.options.should.be.an('object');
    });
  });

  describe('init()', function() {
    it('stores handle, inout and fill elements', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Slider($html, {});

      plugin.$handle.should.be.an('object');
      plugin.$input.should.be.an('object');
      plugin.$fill.should.be.an('object');
    });
    it('stores two handle and input elements for two sided slider', function() {
      $html = $(template).append('<span class="slider-handle" data-slider-handle role="slider" tabindex="1"></span><input type="hidden">')
          .appendTo('body');
      plugin = new Foundation.Slider($html, {doubleSided: true});

      plugin.$handle2.should.be.an('object');
      plugin.$input2.should.be.an('object');
    });
    it('is disabled when disable option is true', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Slider($html, {disabled: true});

      $html.should.have.class('disabled');
    });
  });

  describe('setHandlePos()', function() {
    it('positions the handle', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Slider($html, {});

      plugin._setHandlePos(plugin.$handle, 10, true);

      plugin.$handle[0].style.left.should.not.be.equal('');
    });
    it('does nothing if disabled option is true', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Slider($html, {disabled: true});

      plugin._setHandlePos(plugin.$handle, 10, true);

      plugin.$handle[0].style.left.should.be.equal('');
    });
    it('fires changed.zf.slider event', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Slider($html, {changedDelay: 50});

      $html.on('changed.zf.slider', function(e, $handle) {
        $handle[0].should.be.equal(plugin.$handle[0]);
        done();
      });

      // Rapidly change to see if event fires only once
      for (let i = 0; i < 5; i++) {
        setTimeout(function() {
          plugin._setHandlePos(plugin.$handle, i * 10, true);
        }, i * 20);
      }
    });
    it('fires moved.zf.slider event', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Slider($html, {});

      let timesCallbackCalled = 0;
      $html.on('moved.zf.slider', function(e, $handle) {
        if (++timesCallbackCalled === 5) {
          $handle[0].should.be.equal(plugin.$handle[0]);
          done();
        }
      });

      // Rapidly change to see if event fires multiple times
      for (let i = 0; i < 5; i++) {
        setTimeout(function() {
          plugin._setHandlePos(plugin.$handle, i * 10, true);
        }, i * 20);
      }
    });
  });

  describe('setValues()', function() {
    it('updates ARIA attributes', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Slider($html, {});

      plugin._setValues(plugin.$handle, 10);

      plugin.$handle.should.have.attr('aria-valuenow', '10');
    });
    it('updates input value', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Slider($html, {});

      plugin._setValues(plugin.$handle, 10);

      plugin.$input.val().should.have.be.equal('10');
    });
  });

  describe('setInitAttr()', function() {
    it('adds ARIA attributes to handle', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Slider($html, {
        initialStart: 50,
        end: 70,
        start: 20,
        vertical: true
      });

      plugin.$handle.should.have.attr('role', 'slider');
      plugin.$handle.should.have.attr('aria-controls', plugin.$handle.attr('id'));
      plugin.$handle.should.have.attr('aria-valuemax', '70');
      plugin.$handle.should.have.attr('aria-valuemin', '20');
      plugin.$handle.should.have.attr('aria-valuenow', '50');
      plugin.$handle.should.have.attr('aria-orientation', 'vertical');
      plugin.$handle.should.have.attr('tabindex', '0');
    });
    it('adds attributes to input', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Slider($html, {});

      plugin.$input.should.have.attr('max', '100');
      plugin.$input.should.have.attr('min', '0');
      plugin.$input.should.have.attr('step', '1');
    });
  });

  describe('adjustValue()', function() {
    it('handles positive values', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Slider($html, {});

      plugin._adjustValue(null, 1).should.equal(1);
      plugin._adjustValue(null, 2).should.equal(2);
      plugin._adjustValue(null, 1.2).should.equal(1);
      plugin._adjustValue(null, 1.9).should.equal(2);
      plugin._adjustValue(null, 1.5).should.equal(2);
    });

    it('handles negative values', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Slider($html, {});

      plugin._adjustValue(null, -1).should.equal(-1);
      plugin._adjustValue(null, -2).should.equal(-2);
      plugin._adjustValue(null, -1.2).should.equal(-1);
      plugin._adjustValue(null, -1.9).should.equal(-2);
      plugin._adjustValue(null, -1.5).should.equal(-1);
    });
  });

  describe('keyboard events', function() {
    it('sets value to minimum using HOME', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Slider($html, {});

      plugin.$handle.focus()
        .trigger(window.mockKeyboardEvent('HOME'));

      plugin.$handle.should.have.attr('aria-valuenow', plugin.$handle.attr('aria-valuemin'));
    });
    it('increases value by step size on ARROW_RIGHT', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Slider($html, {
        initialStart: 10,
        step: 1
      });

      plugin.$handle.focus()
        .trigger(window.mockKeyboardEvent('ARROW_RIGHT'));

      plugin.$handle.should.have.attr('aria-valuenow', (10 + 1).toString());
    });
    it('increases value by step size on ARROW_UP', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Slider($html, {
        initialStart: 10,
        step: 1
      });

      plugin.$handle.focus()
        .trigger(window.mockKeyboardEvent('ARROW_UP'));

      plugin.$handle.should.have.attr('aria-valuenow', (10 + 1).toString());
    });
    it('decreases value by step size on ARROW_LEFT', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Slider($html, {
        initialStart: 10,
        step: 1
      });

      plugin.$handle.focus()
        .trigger(window.mockKeyboardEvent('ARROW_LEFT'));

      plugin.$handle.should.have.attr('aria-valuenow', (10 - 1).toString());
    });
    it('decreases value by step size on ARROW_DOWN', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Slider($html, {
        initialStart: 10,
        step: 1
      });

      plugin.$handle.focus()
        .trigger(window.mockKeyboardEvent('ARROW_DOWN'));

      plugin.$handle.should.have.attr('aria-valuenow', (10 - 1).toString());
    });
    it('decreases value by step size times 10 on SHIFT_ARROW_RIGHT', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Slider($html, {
        initialStart: 10,
        step: 1
      });

      plugin.$handle.focus()
        .trigger(window.mockKeyboardEvent('ARROW_RIGHT', {shift: true}));

      plugin.$handle.should.have.attr('aria-valuenow', (10 + 1 * 10).toString());
    });
    it('decreases value by step size times 10 on SHIFT_ARROW_LEFT', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Slider($html, {
        initialStart: 10,
        step: 1
      });

      plugin.$handle.focus()
        .trigger(window.mockKeyboardEvent('ARROW_LEFT', {shift: true}));

      plugin.$handle.should.have.attr('aria-valuenow', (10 - 1 * 10).toString());
    });
  });
});