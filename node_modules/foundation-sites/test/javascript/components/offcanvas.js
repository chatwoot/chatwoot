describe('Off Canvas', function() {
  var plugin;
  var $html;
  var template = `<div class="off-canvas-wrapper">
      <div class="off-canvas-wrapper-inner" data-off-canvas-wrapper>
        <div class="off-canvas position-left" id="offCanvas" data-off-canvas data-content-scroll="false">

          <!-- Close button -->
          <button class="close-button" aria-label="Close menu" type="button" data-close>
            <span aria-hidden="true">&times;</span>
          </button>

          <!-- Menu -->
          <ul class="vertical menu">
            <li><a href="#">Foundation</a></li>
            <li><a href="#">Dot</a></li>
            <li><a href="#">ZURB</a></li>
            <li><a href="#">Com</a></li>
            <li><a href="#">Slash</a></li>
            <li><a href="#">Sites</a></li>
          </ul>

        </div>

        <div class="off-canvas-content" data-off-canvas-content>
          <!-- Page content -->
          PAGE_CONTENT.

          <!-- Triggers -->
          <button type="button" class="button" data-toggle="offCanvas">Open Menu</button>
        </div>
      </div>
    </div>`;

  afterEach(function() {
    plugin.destroy();
    document.activeElement.blur();
    $html.remove();
  });

  describe('constructor()', function() {
    it('stores the element and plugin options', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.OffCanvas($html.find('[data-off-canvas]'), {});

      plugin.$element.should.be.an('object');
      plugin.options.should.be.an('object');
    });
  });

  describe('init()', function() {
    it('finds triggers for the Off Canvas', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.OffCanvas($html.find('[data-off-canvas]'), {});

      plugin.$triggers.length.should.be.equal(1);
    });

    it('sets ARIA attributes', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.OffCanvas($html.find('[data-off-canvas]'), {});

      plugin.$element.should.have.attr('aria-hidden', 'true');
      plugin.$triggers.should.have.attr('aria-controls', plugin.$element.attr('id'));
      plugin.$triggers.should.have.attr('aria-expanded', 'false');
    });

    it('closes Off Canvas on outside click if closeOnClick option is true', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.OffCanvas($html.find('[data-off-canvas]'), {closeOnClick: true});

      plugin.$overlay.should.be.an('object');

      $html.one('opened.zf.offcanvas', function() {
        plugin.$overlay.trigger('click');
        plugin.$element.should.not.have.class('is-open');
        done();
      });

      plugin.open();
    });
  });

  describe('open()', function() {
    it('toggles ARIA attributes', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.OffCanvas($html.find('[data-off-canvas]'), {});

      //$html.one(Foundation.transitionend($html), function() {
      $html.one('opened.zf.offcanvas', function() {
        plugin.$triggers.should.have.attr('aria-expanded', 'true');
        plugin.$element.should.have.attr('aria-hidden', 'false');
        done();
      });

      plugin.open();
    });

    it('adds active classes', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.OffCanvas($html.find('[data-off-canvas]'), {});

      $html.one('opened.zf.offcanvas', function() {
        setTimeout(function() {
          plugin.$element.should.have.class('is-open');
          $('body').should.have.class('is-off-canvas-open');
          done();
        }, 1);
      });

      plugin.open();
    });

    it('focusses Off Canvas if autoFocus option is true', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.OffCanvas($html.find('[data-off-canvas]'), {autoFocus: true});


      plugin.$element.one(Foundation.transitionend(plugin.$element),function() {
        setTimeout(function() {
          plugin.$element.find('a, button')[0].should.be.equal(document.activeElement);
          done();
        }, 1);
      });

      plugin.open();
      // fake transitionend for console tests
      plugin.$element.triggerHandler(Foundation.transitionend(plugin.$element));
    });

    it('traps focus if trapFocus option is true', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.OffCanvas($html.find('[data-off-canvas]'), {trapFocus: true});

      let spy = sinon.spy(Foundation.Keyboard, 'trapFocus');

      $html.one(Foundation.transitionend($html), function() {
        sinon.assert.called(spy);
        Foundation.Keyboard.trapFocus.restore();
        done();
      });

      plugin.open();
    });


    it('fires opened.zf.offcanvas event', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.OffCanvas($html.find('[data-off-canvas]'), {});

      $html.one('opened.zf.offcanvas', function() {
        done();
      });

      plugin.open();
    });
  });

  describe('close()', function() {
    it('toggles ARIA attributes', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.OffCanvas($html.find('[data-off-canvas]'), {});

      $html.one('opened.zf.offcanvas', function() {
        plugin.close();

        plugin.$triggers.should.have.attr('aria-expanded', 'false');
        plugin.$element.should.have.attr('aria-hidden', 'true');
        done();
      });

      // Open it first
      plugin.open();
    });

    it('removes active classes', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.OffCanvas($html.find('[data-off-canvas]'), {});

      $html.one('opened.zf.offcanvas', function() {
        setTimeout(function() {
          plugin.close();

          plugin.$element.should.not.have.class('is-open');
          $('body').should.not.have.class('is-off-canvas-open');
          done();
        }, 1);
      });

      // Open it first
      plugin.open();
    });

    it('fires closed.zf.offcanvas event', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.OffCanvas($html.find('[data-off-canvas]'), {});

      $html.one('opened.zf.offcanvas', function() {
        $html.one('closed.zf.offcanvas', function() {
          done();
        });

        plugin.close();
      });

      // Open it first
      plugin.open();
    });

    it('releases focus if trapFocus option is true', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.OffCanvas($html.find('[data-off-canvas]'), {trapFocus: true});

      $html.one(Foundation.transitionend($html), function() {
        let spy = sinon.spy(Foundation.Keyboard, 'releaseFocus');

        plugin.close();

        sinon.assert.called(spy);
        Foundation.Keyboard.releaseFocus.restore();
      });

      // Open it first...
      plugin.open();
    });
  });

  describe('toggle()', function() {
    it('opens a closed Off Canvas', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.OffCanvas($html.find('[data-off-canvas]'), {});

      $html.one('opened.zf.offcanvas', function() {
        plugin.$element.should.have.class('is-open');
        done();
      });

      plugin.toggle();
    });

    it('closes an open Off Canvas', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.OffCanvas($html.find('[data-off-canvas]'), {});

      $html.one('opened.zf.offcanvas', function() {
        plugin.toggle();

        plugin.$element.should.not.have.class('is-open');
        done();
      });

      // Open it first
      plugin.toggle();
    });
  });

  describe('keyboard events', function() {
    it('closes Off Canvas on ESCAPE', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.OffCanvas($html.find('[data-off-canvas]'), {});

      $html.one('opened.zf.offcanvas', function() {
        plugin.$element.focus()
          .trigger(window.mockKeyboardEvent('ESCAPE'));

        plugin.$element.should.not.have.class('is-open');
        done();
      });

      // Open it first
      plugin.open();
    });
  });

});
