describe('Tabs', function() {
  var plugin;
  var $html;
  var template = `
    <div>
      <ul class="tabs" data-tabs id="example-tabs">
        <li class="tabs-title is-active"><a href="#panel1" aria-selected="true">Tab 1</a></li>
        <li class="tabs-title"><a href="#panel2">Tab 2</a></li>
        <li class="tabs-title"><a data-tabs-target="panel3" href="#/panel3">Tab 3</a></li>
      </ul>

      <div class="tabs-content" data-tabs-content="example-tabs">
        <div class="tabs-panel is-active" id="panel1">
          <p>one</p>
          <p>Check me out! I'm a super cool Tab panel with text content!</p>
        </div>
        <div class="tabs-panel" id="panel2">
          <p>two</p>
          <p>Check me out! I'm a super cool Tab panel with text content!</p>
        </div>
        <div class="tabs-panel" id="panel3">
          <p>three</p>
          <p>Check me out! I'm a super cool Tab panel with text content!</p>
        </div>
      </div>
    </div>`;

  afterEach(function() {
    plugin.destroy();
    $html.remove();
  });

 describe('constructor()', function() {
    it('stores the element and plugin options', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tabs($html.find('[data-tabs]'), {});

      plugin.$element.should.be.an('object');
      plugin.options.should.be.an('object');
    });
  });

  describe('init()', function() {
    it('sets ARIA attributes', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tabs($html.find('[data-tabs]'), {});

      // Panels
      $html.find('#panel1').should.have.attr('role', 'tabpanel');
      $html.find('#panel1').should.have.attr('aria-labelledby', $html.find('[href="#panel1"]').attr('id'));
      $html.find('#panel1').should.not.have.attr('aria-hidden');
      $html.find('#panel2').should.have.attr('aria-hidden', 'true');

      // Links
      $html.find('[href="#panel1"]').should.have.attr('role', 'tab');
      $html.find('[href="#panel1"]').should.have.attr('aria-controls', $html.find('panel1').attr('id'));
      $html.find('[href="#panel1"]').should.have.attr('aria-selected', 'true');
      $html.find('[href="#panel2"]').should.have.attr('aria-selected', 'false');

      // Tab list items
      $html.find('[href="#panel1"]').parent().should.have.attr('role', 'presentation');
    });
  });

  describe('selectTab()', function() {
    it('opens the selected tab via jQuery element', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tabs($html.find('[data-tabs]'), {});

      plugin.selectTab($html.find('#panel2'));
      $html.find('#panel2').should.be.visible;
    });

    it('opens the selected tab via id string', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tabs($html.find('[data-tabs]'), {});

      plugin.selectTab('#panel2');
      $html.find('#panel2').should.be.visible;
    });
    it('opens the selected tab with data-tabs-target attribute', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tabs($html.find('[data-tabs]'), {});

      plugin.selectTab('#/panel3');
      $html.find('#panel3').should.be.visible;
    });
  });

  describe('_handleTabChange()', function() {
    it('opens the selected tab', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tabs($html.find('[data-tabs]'), {});

      plugin.selectTab('#panel2');
      $html.find('#panel2').should.be.visible;
      $html.find('#panel2').should.have.class('is-active');
    });

    it('sets ARIA attributes for open tab', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tabs($html.find('[data-tabs]'), {});

      plugin.selectTab('#panel2');
      $html.find('#panel2').should.have.not.attr('aria-hidden');
      $html.find('[href="#panel2"]').should.have.attr('aria-selected', 'true');
    });

    it('hides the open tab', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tabs($html.find('[data-tabs]'), {});

      plugin.selectTab('#panel2');
      $html.find('#panel1').should.be.hidden;
      $html.find('#panel1').should.not.have.class('is-active');
    });

    it('sets ARIA attributes for closed tab', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tabs($html.find('[data-tabs]'), {});

      plugin.selectTab('#panel2');
      $html.find('#panel1').should.be.have.attr('aria-hidden', 'true');
      $html.find('[href="#panel1"]').should.be.have.attr('aria-selected', 'false');
    });

    it('fires change.zf.tabs event with target as data', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tabs($html.find('[data-tabs]'), {});

      $html.one('change.zf.tabs', function(e, $target) {
        e.stopPropagation();
        $html.find('[href="#panel2"]').parent()[0].should.be.equal($target[0]);
        done();
      });

      plugin.selectTab('#panel2');
    });
  });

  describe('keyboard events', function() {
    it('switches to next tab on ARROW_RIGHT', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tabs($html.find('[data-tabs]'), {});

      $html.find('[href="#panel1"]').focus()
        .trigger(window.mockKeyboardEvent('ARROW_RIGHT'));

      $html.find('#panel2').should.be.visible;
      $html.find('#panel2').should.have.class('is-active');
    });
    it('switches to next tab on ARROW_DOWN', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tabs($html.find('[data-tabs]'), {});

      $html.find('[href="#panel1"]').focus()
        .trigger(window.mockKeyboardEvent('ARROW_DOWN'));

      $html.find('#panel2').should.be.visible;
      $html.find('#panel2').should.have.class('is-active');
    });
    it('switches to previous tab on ARROW_LEFT', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tabs($html.find('[data-tabs]'), {});

      $html.find('[href="#panel2"]').focus()
        .trigger(window.mockKeyboardEvent('ARROW_LEFT'));

      $html.find('#panel1').should.be.visible;
      $html.find('#panel1').should.have.class('is-active');
    });
    it('switches to previous tab on ARROW_UP', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tabs($html.find('[data-tabs]'), {});

      $html.find('[href="#panel2"]').focus()
        .trigger(window.mockKeyboardEvent('ARROW_UP'));

      $html.find('#panel1').should.be.visible;
      $html.find('#panel1').should.have.class('is-active');
    });
  });
});
