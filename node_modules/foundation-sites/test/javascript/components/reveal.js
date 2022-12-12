describe('Reveal', function() {
	var plugin;
	var $html;
	var template = `<div class="reveal" id="exampleModal1" data-reveal>
	  Modal content
	  <button class="close-button" data-close aria-label="Close modal" type="button">
	    <span aria-hidden="true">&times;</span>
	  </button>
	</div>`;

  afterEach(function() {
    plugin.destroy();
    document.activeElement.blur();
    $html.remove();
  });

  describe('constructor()', function() {
    it('stores the element and plugin options', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {});

      plugin.$element.should.be.an('object');
      plugin.options.should.be.an('object');
    });
  });

  describe('init()', function() {
    it('sets ARIA attributes for modal', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {});

      $html.should.have.attr('aria-hidden', 'true');
      $html.should.have.attr('role', 'dialog');
    });

    it('detects anchor if one exists', function() {
      $html = $(template).appendTo('body');
      var $anchor = $('<button data-open="exampleModal1">Open</button>').appendTo('body');
      plugin = new Foundation.Reveal($html, {});

      plugin.$anchor[0].should.be.equal($anchor[0]);

      $anchor.remove();
    });

    it('sets ARIA attributes for anchor if one exists', function() {
      $html = $(template).appendTo('body');
      var $anchor = $('<button data-open="exampleModal1">Open</button>').appendTo('body');
      plugin = new Foundation.Reveal($html, {});

      $anchor.should.have.attr('aria-haspopup', 'true');
      $anchor.should.have.attr('aria-controls', $html.attr('id'));

      $anchor.remove();
    });
  });

  describe('makeOverlay()', function() {
		it('creates an overlay if overlay option is true', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {overlay: true});

      plugin.$overlay.should.be.an('object');
      plugin.$overlay.should.have.class('reveal-overlay');
      $.contains(document.body, plugin.$overlay[0]).should.be.true;
    });
  });

  describe('open()', function() {
		it('opens the modal', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {});

      $html.on('open.zf.reveal', function() {
        $html.should.be.visible;
        done();
      });

      plugin.open();
    });
    it('opens the overlay', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {overlay: true});

      $html.on('open.zf.reveal', function() {
        plugin.$overlay.should.be.visible;
        done();
      });

      plugin.open();
    });
    it('toggles ARIA attributes', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {});

      $html.on('open.zf.reveal', function() {
        $html.should.have.attr('aria-hidden', 'false');
        $html.should.have.attr('tabindex', '-1');
        done();
      });

      plugin.open();
    });
    it('adds class to body', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {});

      $html.on('open.zf.reveal', function() {
        $('html').should.have.class('is-reveal-open');
        done();
      });

      plugin.open();
    });
    it('adds optional overlay classes overlay element', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {additionalOverlayClasses: 'default'});

      $html.on('open.zf.reveal', function() {
        $('.reveal-overlay').should.have.class('default');
        done();
      });

      plugin.open();
    });
    // TODO: Check if  this.$element.trigger('closeme.zf.reveal', this.id) is correctly used.

    // it('closes previously opened modal if multipleOpened option is false', function(done) {
    //   $html = $(template).appendTo('body');
    //   $html2 = $(template).attr('id', 'exampleModal2').appendTo('body');

    //   plugin = new Foundation.Reveal($html, {multipleOpened: false});
    //   plugin2 = new Foundation.Reveal($html2, {multipleOpened: false});

    //   plugin.open();

    //   plugin2.open();

    //   $html.should.be.hidden;

    //   plugin2.destroy();
    //   $html2.remove();
    // });
    it('fires open.zf.reveal event', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {});

      $html.on('open.zf.reveal', function() {
      	$html.should.be.visible;
      	done();
      });

      plugin.open();
    });

    it('traps focus if trapFocus option is true', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {trapFocus: true});

      let spy = sinon.spy(Foundation.Keyboard, 'trapFocus');

      $html.on('open.zf.reveal', function() {
        sinon.assert.called(spy);
        Foundation.Keyboard.trapFocus.restore();
      	done();
      });

      plugin.open();
    });
  });

	describe('close()', function() {
		it('closes the modal', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {});

      // Open it first
      plugin.open();

      $html.on('closed.zf.reveal', function() {
        $html.should.be.hidden;
      	done();
      });

      plugin.close();
    });
    it('closes the overlay', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {overlay: true});

      // Open it first
      plugin.open();

      $html.on('closed.zf.reveal', function() {
        plugin.$overlay.should.be.hidden;
      	done();
      });

      plugin.close();
    });
    it('toggles ARIA attributes', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {});

      // Open it first
      plugin.open();

      $html.on('closed.zf.reveal', function() {
        $html.should.have.attr('aria-hidden', 'true');
      	done();
      });

      plugin.close();
    });
    it('removes class from body', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {});

      // Open it first
      plugin.open();


      $html.on('closed.zf.reveal', function() {
        $('html').should.not.have.class('is-reveal-open');
        done();
      });

      plugin.close();
    });
    it('does not remove class from body if another reveal is open', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {multipleOpened: true});

      let $html2 = $(template).attr('id', 'exampleModal2').appendTo('body');
      let plugin2 = new Foundation.Reveal($html2, {multipleOpened: true, vOffset: 10});

      // Open both first
      plugin.open();
      plugin2.open();


      $html.on('closed.zf.reveal', function() {

        $('html').should.have.class('is-reveal-open');
        plugin2.destroy();
        $html2.remove();
        done();
      });

      plugin.close();
    });
    it('fires closed.zf.reveal event', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {});

      // Open it first
      plugin.open();

      $html.on('closed.zf.reveal', function() {
      	$html.should.be.hidden;
      	done();
      });

      plugin.close();
    });

    it('releases focus if trapFocus option is true', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {trapFocus: true});

      // Open it first
      plugin.open();

      let spy = sinon.spy(Foundation.Keyboard, 'releaseFocus');

      $html.on('closed.zf.reveal', function() {
        sinon.assert.called(spy);
        Foundation.Keyboard.releaseFocus.restore();
        done();
      });

      plugin.close();
    });
    it('sets focus to anchor', function(done) {
      $html = $(template).appendTo('body');
      var $anchor = $('<button data-open="exampleModal1">Open</button>').appendTo('body');
      plugin = new Foundation.Reveal($html, {});

      // Open it first
      plugin.open();

      $html.on('closed.zf.reveal', function() {
        setTimeout(function() {
          $anchor[0].should.be.equal(document.activeElement);
          $anchor.remove();
          done();
        }, 0);
      });

      plugin.close();
    });
    it('sets focus to anchor that opened it', function(done) {
      $html = $(template).appendTo('body');
      var $anchor = $('<button data-open="exampleModal1">Open</button>').appendTo('body');
      var $anchor2 = $('<button data-open="exampleModal1">Open2</button>').appendTo('body');
      plugin = new Foundation.Reveal($html, {});
      $anchor.focus();

      // Open it first
      plugin.open();

      $html.on('closed.zf.reveal', function() {
        setTimeout(function() {
          $anchor[0].should.be.equal(document.activeElement);
          $anchor.remove();
          $anchor2.remove();
          done();
        }, 0);
      });

      plugin.close();
    });
  });

	describe('toggle()', function() {
    it('opens a closed modal', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {overlay: true});

      $html.on('open.zf.reveal', function() {
        plugin.$overlay.should.be.visible;
        done();
      });

      plugin.open();
    });
		it('closes an open modal', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {});

      // Open it first
      plugin.open();

      $html.on('closed.zf.reveal', function() {
        $html.should.be.hidden;
      	done();
      });

      plugin.close();
    });
  });

  describe('events()', function() {
    it('opens the modal on anchor click', function(done) {
      $html = $(template).appendTo('body');
      var $anchor = $('<button data-open="exampleModal1">Open</button>').appendTo('body');
      plugin = new Foundation.Reveal($html, {});


      $html.on('open.zf.reveal', function() {
        plugin.$overlay.should.be.visible;
        $anchor.remove();
      	done();
      });

      $anchor.trigger('click');
    });
		it('closes a modal on overlay click if closeOnClick option is true', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {overlay: true, closeOnClick: true});

      // Open it first
      plugin.open();

      $html.on('closed.zf.reveal', function() {
        $html.should.be.hidden;
      	done();
      });

      plugin.$overlay.trigger('click');
    });
    it('not closes a modal on overlay click if closeOnClick option is true', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {overlay: true, closeOnClick: false});

      // Open it first
      plugin.open();

      plugin.$overlay.trigger('click');

      // Add timeout to make sure it does not close
      // Timeout is required because closed event will not be fired
      setTimeout(function() {
        $html.should.be.visible;
        done();
      }, 10);
    });
    it('closes Reveal with click on close button', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Reveal($html, {});

      // Open it first
      plugin.open();

      $html.on('closed.zf.reveal', function() {
        $html.should.be.hidden;
      	done();
      });

      $html.find('[data-close]').focus()
        .trigger('click');
    });
  });
});
