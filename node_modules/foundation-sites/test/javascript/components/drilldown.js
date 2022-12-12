describe('Drilldown Menu', function() {
  var plugin;
  var $html;
  var template = `<ul class="menu" data-drilldown style="width: 200px" id="m1">
    <li>
      <a href="#">Item 1</a>
      <ul id="Menu-1" class="menu">
        <li>
          <a href="#">Item 1A</a>
          <ul id="Menu-1A" class="menu">
            <li><a href="#Item-1Aa">Item 1Aa</a></li>
          </ul>
        </li>
        <li><a href="#Item-1B">Item 1B</a></li>
        <li><a href="#Item-1C">Item 1C</a></li>
      </ul>
    </li>
    <li>
      <a href="#">Item 2</a>
      <ul id="Menu-2" class="menu">
        <li><a href="#Item-2A">Item 2A</a></li>
        <li><a href="#Item-2B">Item 2B</a></li>
      </ul>
    </li>
    <li><a href="#Item-3"> Item 3</a></li>
  </ul>`;

  var templateWithToggler = `
    <div>
      <button id="trigger" data-toggle="target" type="button">Toggler</button>
      <div id="target" class="is-hidden" data-toggler="is-hidden">
        ${template}
      </div>
    </div>
  `;

  afterEach(function() {
    plugin.destroy();
    document.activeElement.blur();
    $html.remove();
  });

  describe('constructor()', function() {
    it('stores the element and plugin options', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      plugin.$element.should.be.an('object');
      plugin.options.should.be.an('object');
    });
  });

  describe('init()', function() {
    it('stores additional elements', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      plugin.$submenuAnchors.should.be.an('object');
      plugin.$submenus.should.be.an('object');
      plugin.$menuItems.should.be.an('object');
    });
  });

  describe('prepareMenu()', function() {
    it('wraps the submenus', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

    });
    it('adds ARIA attributes', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      plugin.$element.should.have.attr('role', 'tree');

      plugin.$element.find('[data-submenu]').each(function() {
        $(this).should.have.attr('role', 'group');
        $(this).should.have.attr('aria-hidden', 'true');
      });

      plugin.$element.find('.is-drilldown-submenu-parent').each(function() {
        $(this).should.have.attr('aria-haspopup', 'true');
        $(this).should.have.attr('aria-expanded', 'false');
        $(this).should.have.attr('aria-label', $(this).children('a').first().text());
      });

      plugin.$element.find('li:not(.js-drilldown-back)').each(function() {
        $(this).should.have.attr('role', 'treeitem');
      });
    });
  });

  describe('show()', function() {
    it('shows the given submenu', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      plugin._show($html.find('li.is-drilldown-submenu-parent').eq(0));

      // Checking with .be.hidden is not possible because they don't have display: block but z-index: -1
      $html.find('li.is-drilldown-submenu-parent').eq(0).find('ul').should.have.class('is-active');
    });
    it('toggles ARIA attributes', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      plugin._show($html.find('li.is-drilldown-submenu-parent').eq(0));

      $html.find('li.is-drilldown-submenu-parent').eq(0).should.have.attr('aria-expanded', 'true');
      $html.find('li.is-drilldown-submenu-parent').eq(0).children('ul').should.have.attr('aria-hidden', 'false');
    });
    it('fires open.zf.drilldown event', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      $html.on('open.zf.drilldown', function() {
        // Checking with .be.hidden is not possible because they don't have display: block but z-index: -1
        $html.find('li.is-drilldown-submenu-parent').eq(0).find('ul').should.have.class('is-active');
        done();
      });

      plugin._show($html.find('li.is-drilldown-submenu-parent').eq(0));
    });
  });

  describe('hide()', function() {
    it('hides the given submenu', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      // Open it first
      plugin._show($html.find('li.is-drilldown-submenu-parent').eq(0));

      plugin._hide($html.find('li.is-drilldown-submenu-parent').eq(0).children('ul'));

      // Checking with .be.hidden is not possible because they don't have display: block but z-index: -1
      $html.find('li.is-drilldown-submenu-parent').eq(0).children('ul').should.have.class('is-closing');
    });
    it('toggles ARIA attributes', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      // Open it first
      plugin._show($html.find('li.is-drilldown-submenu-parent').eq(0));

      plugin._hide($html.find('li.is-drilldown-submenu-parent').eq(0).children('ul'));

      $html.find('li.is-drilldown-submenu-parent').eq(0).should.have.attr('aria-expanded', 'false');
      $html.find('li.is-drilldown-submenu-parent').eq(0).children('ul').should.have.attr('aria-hidden', 'true');
    });
    it('fires hide.zf.drilldown event', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      // Open it first
      plugin._show($html.find('li.is-drilldown-submenu-parent').eq(0));

      $html.on('hide.zf.drilldown', function() {
        // Checking with .be.hidden is not possible because they don't have display: block but z-index: -1
        $html.find('li.is-drilldown-submenu-parent').eq(0).children('ul').should.have.class('is-closing');
        done();
      });

      plugin._hide($html.find('li.is-drilldown-submenu-parent').eq(0).children('ul'));
    });
  });

  describe('hideAll()', function() {
    it('hides all submenus', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      // Open one first
      plugin._show($html.find('li.is-drilldown-submenu-parent').eq(2));

      plugin._hideAll();

      $html.find('ul[data-submenu].is-active').each(function() {
        // Checking with .be.hidden is not possible because they don't have display: block but z-index: -1
        $(this).should.have.class('is-closing');
      });
    });
    it('fires closed.zf.drilldown event', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      // Open one first
      plugin._show($html.find('li.is-drilldown-submenu-parent').eq(2));

      $html.one('closed.zf.drilldown', function() {
        $html.find('ul[data-submenu].is-active').each(function() {
          // Checking with .be.hidden is not possible because they don't have display: block but z-index: -1
          $(this).should.have.class('is-closing');
        });
        done();
      });

      plugin._hideAll();
    });
  });

  describe('back()', function() {
    it('hides current submenu', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      // Open one first
      plugin._show($html.find('li.is-drilldown-submenu-parent').eq(1));

      $html.find('li.is-drilldown-submenu-parent').eq(1).children('ul').children('.js-drilldown-back').trigger('click');

      // Checking with .be.hidden is not possible because they don't have display: block but z-index: -1
      $html.find('li.is-drilldown-submenu-parent').eq(1).children('ul').should.have.class('is-closing');
    });
    it('shows parent submenu', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      // Open one first
      plugin._show($html.find('li.is-drilldown-submenu-parent').eq(1));

      $html.find('li.is-drilldown-submenu-parent').eq(1).children('ul').children('.js-drilldown-back').trigger('click');

      // Checking with .be.hidden is not possible because they don't have display: block but z-index: -1
      $html.find('li.is-drilldown-submenu-parent').eq(0).children('ul').should.have.class('is-active');
    });
  });

  describe('toggle events', function () {

    var $trigger, $target, $wrapper, togglerPlugin;

    beforeEach(function () {
      $html = $(templateWithToggler).appendTo('body');
      $trigger = $html.find('#trigger');
      $target = $html.find('#target');
      $target = $html.find('#target');

      togglerPlugin = new Foundation.Toggler($target, {});
      plugin = new Foundation.Drilldown($html.find('[data-drilldown]'), { autoHeight: true });

      $wrapper = $html.find('.is-drilldown');
    });

    it('correctly resize when opened', function () {
      // Open the Drilldown
      $trigger.focus().trigger('click');

      // 3 items (including the back button) is around 115px height
      $wrapper.height().should.be.within(110, 120);
    });

    it('correctly resize when closed', function () {
      // Open then close the Drilldown
      $trigger.focus().trigger('click');
      $trigger.focus().trigger('click');

      $wrapper.height().should.be.equal(0);
    });

    it('correctly resize when reopened on a submenu', function () {
      // Open the Drilldown
      $trigger.focus().trigger('click');
      // Show a submenu with a smaller height
      plugin._showMenu($html.find('#Menu-1A'));
      // Close then reopen the the Drilldown
      $trigger.focus().trigger('click');
      $trigger.focus().trigger('click');

      // 2 items (including the back button) is around 75px height
      $wrapper.height().should.be.within(70, 80);
    });

    afterEach(function () {
      togglerPlugin.destroy();
    });

  });

  describe('keyboard events', function() {
    // Currently not testable, as triggered event won't move on focus
    it.skip('does not trap focus on root element going down', function() {
      $html = $(template).appendTo('body');
      let $dummyElement = $('<a tabindex="0">Dummy</a>').appendTo('body'); // Dummy target to see if focus is not trapped
      plugin = new Foundation.Drilldown($html, {});

      // Focus last element
      $dummyElement.focus();
      $html.find('> li:last-child > a').trigger(window.mockKeyboardEvent('TAB'));

      document.activeElement.should.not.be.equal($html.find('> li:last-child > a')[0]);

      $dummyElement.remove();
    });
    // Currently not testable, as triggered event won't move on focus
    it.skip('does not trap focus on root element going up', function() {
      let $dummyElement = $('<a tabindex="0">Dummy</a>').appendTo('body'); // Dummy target to see if focus is not trapped
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      // Focus first element
      $dummyElement.focus();
      $html.find('> li:first-child > a').trigger(window.mockKeyboardEvent('TAB', {shift: true}));

      document.activeElement.should.not.be.equal($html.find('> li:first-child > a')[0]);

      $dummyElement.remove();
    });
    it('closes current sub menu using ESC', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      // Open it first
      plugin._show($html.find('> li:nth-child(1)'))

      $html.find('> li:nth-child(1) > ul > li:first-child > a').focus()
        .trigger(window.mockKeyboardEvent('ESCAPE'));

      $html.find('> li:nth-child(1) > ul').should.have.class('is-closing');
    });
    it('moves focus to next element on TAB', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      $html.find('> li:nth-child(1) > a').focus()
        .trigger(window.mockKeyboardEvent('TAB'));

      document.activeElement.should.be.equal($html.find('> li:nth-child(2) > a')[0]);
    });
    it('moves focus to previous element on TAB', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      $html.find('> li:nth-child(2) > a').focus()
        .trigger(window.mockKeyboardEvent('TAB', {shift: true}));

      document.activeElement.should.be.equal($html.find('> li:nth-child(1) > a')[0]);
    });
    it('moves focus to next element on ARROW_DOWN', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      $html.find('> li:nth-child(1) > a').focus()
        .trigger(window.mockKeyboardEvent('ARROW_DOWN'));

      document.activeElement.should.be.equal($html.find('> li:nth-child(2) > a')[0]);
    });
    it('moves focus to previous element on ARROW_UP', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      $html.find('> li:nth-child(2) > a').focus()
        .trigger(window.mockKeyboardEvent('ARROW_UP'));

      document.activeElement.should.be.equal($html.find('> li:nth-child(1) > a')[0]);
    });
    it('opens child element on ARROW_RIGHT', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      $html.find('> li:nth-child(1) > a').focus()
        .trigger(window.mockKeyboardEvent('ARROW_RIGHT'));

      $html.find('> li:nth-child(1) > ul').should.have.class('is-active');
    });
    it('focuses parent link if parentLink is true', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {parentLink: true});

      $html.find('> li:nth-child(1) > a').focus()
        .trigger(window.mockKeyboardEvent('ARROW_RIGHT'));

      setTimeout(function() { // Timeout to make sure transition has ended
        $html.find('> li:nth-child(1) > ul > li[data-is-parent-link] a')[0].should.be.equal(document.activeElement);
        done();
      }, 500);
    });
    it('closes child element on ARROW_LEFT', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Drilldown($html, {});

      // Open it first
      plugin._show($html.find('> li:nth-child(1)'))

      $html.find('> li:nth-child(1) > ul > li:first-child > a').focus()
        .trigger(window.mockKeyboardEvent('ARROW_LEFT'));

      $html.find('> li:nth-child(1) > ul').should.have.class('is-closing');
    });
  });
});
