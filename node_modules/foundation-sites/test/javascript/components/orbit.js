describe('Orbit', function() {
  var plugin;
  var $html;
  var template = `<div class="orbit" role="region" aria-label="Favorite Space Pictures" data-orbit>
    <ul class="orbit-container">
      <button class="orbit-previous"><span class="show-for-sr">Previous Slide</span>&#9664;&#xFE0E;</button>
      <button class="orbit-next"><span class="show-for-sr">Next Slide</span>&#9654;&#xFE0E;</button>
      <li class="is-active orbit-slide">
        Slide #1 content.
      </li>
      <li class="orbit-slide">
        Slide #2 content.
      </li>
      <li class="orbit-slide">
        Slide #3 content.
      </li>
      <li class="orbit-slide">
        Slide #4 content.
      </li>
    </ul>
    <nav class="orbit-bullets">
      <button class="is-active" data-slide="0"><span class="show-for-sr">First slide details.</span><span class="show-for-sr">Current Slide</span></button>
      <button data-slide="1"><span class="show-for-sr">Second slide details.</span></button>
      <button data-slide="2"><span class="show-for-sr">Third slide details.</span></button>
      <button data-slide="3"><span class="show-for-sr">Fourth slide details.</span></button>
    </nav>
  </div>`;
  Foundation.Orbit.defaults.useMUI = false;

  afterEach(function() {
    plugin.destroy();
    $html.remove();
  });

  describe('constructor()', function() {
    it('stores the element and plugin options', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Orbit($html, {});

      plugin.$element.should.be.an('object');
      plugin.$wrapper.should.be.an('object');
      plugin.$slides.should.be.an('object');
      plugin.options.should.be.an('object');
    });
  });

  describe('init()', function() {
    it('shows the first slide', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Orbit($html, {});

      $html.find('.orbit-slide').eq(0).should.be.visible;
    });
    it('hides all slides except the first one', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Orbit($html, {});

      $html.find('.orbit-slide').each(function(index) {
        if (index === 0) {return;} // Not for the first one as this is visible
        $(this).should.be.hidden;
      });
    });
    it('makes slide with is-active class active initially', function() {
      $html = $(template).appendTo('body');
      $html.find('.orbit-slide.is-active').removeClass('is-active');
      $html.find('.orbit-slide').eq(2).addClass('is-active');
      plugin = new Foundation.Orbit($html, {});

      $html.find('.orbit-slide').eq(2).should.be.visible;
    });
  });

  describe('loadBullets()', function() {
    it('stores the bullets', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Orbit($html, {});

      plugin.$bullets.should.be.an('object');
    });
  });

  describe('changeSlide()', function() {
    it('changes slides to the next one for ltr is true', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Orbit($html, {});

      plugin.changeSlide(true);

      $html.find('.orbit-slide').eq(0).should.be.hidden;
      $html.find('.orbit-slide').eq(1).should.be.visible;
    });
    it('changes slides to the last one for ltr is false', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Orbit($html, {});

      plugin.changeSlide(false);

      $html.find('.orbit-slide').eq(0).should.not.have.class('is-active');
      $html.find('.orbit-slide').eq(-1).should.have.class('is-active');
    });
    it('changes slides to the chosen one', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Orbit($html, {});

      plugin.changeSlide(true, $html.find('.orbit-slide').eq(2), 2);

      $html.find('.orbit-slide').eq(0).should.be.hidden;
      $html.find('.orbit-slide').eq(2).should.be.visible;
    });
    it('toggles ARIA attributes', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Orbit($html, {});

      plugin.changeSlide(true);

      $html.find('.orbit-slide').eq(0).should.not.have.attr('aria-live');
      $html.find('.orbit-slide').eq(1).should.have.attr('aria-live', 'polite');
    });
    it('fires beforeslidechange.zf.orbit event', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Orbit($html, {});

      $html.on('beforeslidechange.zf.orbit', function() {
        // Old slide should still be active
        $html.find('.orbit-slide').eq(0).should.be.visible;
        done();
      });
      plugin.changeSlide(true);
    });
    it('fires slidechange.zf.orbit event', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Orbit($html, {});

      $html.on('slidechange.zf.orbit', function() {
        // New slide is already active
        $html.find('.orbit-slide').eq(1).should.be.visible;
        done();
      });
      plugin.changeSlide(true);
    });
  });

  describe('updateBullets()', function() {
    it('updates the bullets', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Orbit($html, {});

      plugin.changeSlide(true);

      $html.find('.orbit-bullets [data-slide]').eq(0).should.not.have.class('is-active');
      $html.find('.orbit-bullets [data-slide]').eq(1).should.have.class('is-active');
    });
  });

  describe('events()', function() {
    it('changes slides on bullet click', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Orbit($html, {});

      $html.find('.orbit-bullets [data-slide]').eq(2).trigger('click');

      $html.find('.orbit-slide').eq(0).should.be.hidden;
      $html.find('.orbit-slide').eq(2).should.be.visible;
    });
    it('changes slides to the previous one', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Orbit($html, {});

      $html.find('.orbit-previous').trigger('click');

      $html.find('.orbit-slide').eq(0).should.be.hidden;
      $html.find('.orbit-slide').eq(-1).should.be.visible;
    });
    it('changes slides to the next one', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Orbit($html, {});

      $html.find('.orbit-next').trigger('click');

      $html.find('.orbit-slide').eq(0).should.be.hidden;
      $html.find('.orbit-slide').eq(1).should.be.visible;
    });
  });

  describe('geoSync()', function() {
    it('changes slides automatically based on timerDelay option', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Orbit($html, {timerDelay: 200});

      setTimeout(function() {
        $html.find('.orbit-slide').eq(0).should.be.hidden;
        $html.find('.orbit-slide').eq(1).should.be.visible;
        done();
      }, 201);
    });
  });

  describe('keyboard events', function() {
    it('moves switches to next slide using ARROW_RIGHT', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Orbit($html, {});
      let spy = sinon.spy(plugin, 'changeSlide');

      plugin.$wrapper.focus()
        .trigger(window.mockKeyboardEvent('ARROW_RIGHT'));

      sinon.assert.calledWith(spy, true);
    });
    it('moves switches to previous slide using ARROW_LEFT', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Orbit($html, {});
      let spy = sinon.spy(plugin, 'changeSlide');

      plugin.$wrapper.focus()
        .trigger(window.mockKeyboardEvent('ARROW_LEFT'));

      sinon.assert.calledWith(spy, false);
    });
  });
});