describe('Accordion Menu', function() {
  var plugin;
  var $html;
  var template = `
    <ul class="vertical menu">
      <li>
        <a href="#">Item 1</a>
        <ul class="menu vertical nested">
          <li>
            <a href="#">Item 1A</a>
            <ul class="menu vertical nested">
              <li><a href="#">Item 1Ai</a></li>
              <li><a href="#">Item 1Aii</a></li>
              <li><a href="#">Item 1Aiii</a></li>
            </ul>
          </li>
          <li><a href="#">Item 1B</a></li>
          <li><a href="#">Item 1C</a></li>
        </ul>
      </li>
      <li>
        <a href="#">Item 2</a>
        <ul class="menu vertical nested">
          <li><a href="#">Item 2A</a></li>
          <li><a href="#">Item 2B</a></li>
        </ul>
      </li>
      <li><a href="#">Item 3</a></li>
    </ul>`;
  Foundation.AccordionMenu.defaults.slideSpeed = 0;

  afterEach(function() {
    plugin.destroy();
    $html.remove();
  });

  describe('constructor()', function() {
    it('stores the element and plugin options', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.AccordionMenu($html, {});

      plugin.$element.should.be.an('object');
      plugin.options.should.be.an('object');
    });
  });

  describe('up()', function() {
    it('closes the targeted submenu', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.AccordionMenu($html);
      const $submenu = $html.find('.is-accordion-submenu').eq(0);

      // Open it first
      plugin.down($submenu);

      plugin.up($submenu);

      setTimeout(() => {
        // Should be hidden
        $submenu.should.be.hidden;
        // Should have attributes updated and without active classe
        $submenu.should.have.attr('aria-hidden', 'true');
        $submenu.should.not.have.class('is-active');
        done();
      }, 1);
    });

    it('toggles attributes of title of the targeted container', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.AccordionMenu($html, {});

      // Open it first
      plugin.down($html.find('.is-accordion-submenu').eq(0));

      plugin.up($html.find('.is-accordion-submenu').eq(0));
      $html.find('.is-accordion-submenu-parent').eq(0).should.have.attr('aria-expanded', 'false');
    });

    it('fires up.zf.accordionMenu event', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.AccordionMenu($html, {slideSpeed: 200});

      // Open it first
      plugin.down($html.find('.is-accordion-submenu').eq(0));

      $html.on('up.zf.accordionMenu', function() {
        $html.find('.is-accordion-submenu').eq(0).should.be.hidden;
        done();
      });
      plugin.up($html.find('.is-accordion-submenu').eq(0));
    });
  });

  describe('down()', function() {
    it('opens the targeted submenu', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.AccordionMenu($html, {});
      const $submenu = $html.find('.is-accordion-submenu').eq(0);

      plugin.down($submenu);

      // Should be visible
      $submenu.should.be.visible;
      // Should have attributes updated and with an active classe
      $submenu.should.have.attr('aria-hidden', 'false');
      $submenu.should.have.class('is-active');
    });

    it('toggles attributes of title of the targeted submenu', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.AccordionMenu($html, {});

      plugin.down($html.find('.is-accordion-submenu').eq(0));
      $html.find('.is-accordion-submenu-parent').eq(0).should.have.attr('aria-expanded', 'true');
    });

    it('closes open submenu if multiOpen is false', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.AccordionMenu($html, {multiOpen: false});

      // Open another one first
      plugin.down($html.find('.is-accordion-submenu').eq(0));

      plugin.down($html.find('.is-accordion-submenu').eq(2));
      $html.find('.is-accordion-submenu').eq(0).should.be.hidden;
    });

    it('not closes open submenu if multiOpen is true', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.AccordionMenu($html, {multiOpen: true});

      // Open another one first
      plugin.down($html.find('.is-accordion-submenu').eq(0));

      plugin.down($html.find('.is-accordion-submenu').eq(2));
      $html.find('.is-accordion-submenu').eq(0).should.be.visible;
    });

    it('fires down.zf.accordionMenu event', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.AccordionMenu($html, {slideSpeed: 200});

      $html.on('down.zf.accordionMenu', function() {
        $html.find('.is-accordion-submenu').eq(0).should.be.visible;
        done();
      });
      plugin.down($html.find('.is-accordion-submenu').eq(0));
    });
  });

  describe('toggle()', function() {
    it('opens a closed container', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.AccordionMenu($html, {});

      plugin.toggle($html.find('.is-accordion-submenu').eq(0));
      $html.find('.is-accordion-submenu').eq(0).should.be.visible;
    });

    it('closes an open container', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.AccordionMenu($html, {});

      // Open first
      plugin.down($html.find('.is-accordion-submenu').eq(0));

      plugin.toggle($html.find('.is-accordion-submenu').eq(0));
      $html.find('.is-accordion-submenu').eq(0).should.be.hidden;
    });
  });

  describe('hideAll()', function() {
    it('closes all accordions', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.AccordionMenu($html, {});

      // Open some first
      plugin.down($html.find('.is-accordion-submenu').eq(0));
      plugin.down($html.find('.is-accordion-submenu').eq(1));
      plugin.down($html.find('.is-accordion-submenu').eq(2));

      plugin.hideAll();

      $html.find('[data-submenu]').each(function() {
        $(this).should.be.hidden;
      });
    });
  });

});
