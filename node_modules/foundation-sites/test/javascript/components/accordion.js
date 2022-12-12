describe('Accordion', function() {
  var plugin;
  var $html;
  var template = `<ul class="accordion" data-accordion>
  <li class="accordion-item is-active" data-accordion-item>
    <a href="#" class="accordion-title">Accordion 1</a>
    <div class="accordion-content" data-tab-content >
      <p>Panel 1. Lorem ipsum dolor</p>
      <a href="#">Nowhere to Go</a>
    </div>
  </li>
  <li class="accordion-item" data-accordion-item>
    <a href="#" class="accordion-title">Accordion 2</a>
    <div class="accordion-content" data-tab-content>
      <textarea></textarea>
      <button class="button">I do nothing!</button>
    </div>
  </li>
  <li class="accordion-item" data-accordion-item>
    <a href="#" class="accordion-title">Accordion 3</a>
    <div class="accordion-content" data-tab-content>
      Pick a date!
      <input type="date"></input>
    </div>
  </li>
</ul>`;

  afterEach(function() {
    plugin.destroy();
    document.activeElement.blur();
    $html.remove();
  });

  describe('constructor()', function() {
    it('stores the element and plugin options', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Accordion($html, {});

      plugin.$element.should.be.an('object');
      plugin.options.should.be.an('object');
    });
  });

  describe('up()', function(done) {
    it('closes the targeted container if allowAllClosed is true', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Accordion($html, {allowAllClosed: true});

      plugin.up($html.find('.accordion-content').eq(0));
      $html.find('.accordion-content').eq(0).should.have.attr('aria-hidden', 'true');
      $html.on('up.zf.accordion', function() {
        $html.find('.accordion-content').eq(0).should.be.hidden;
        done();
      });
    });

    it('toggles attributes of title of the targeted container', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Accordion($html, {allowAllClosed: true});

      plugin.up($html.find('.accordion-content').eq(0));
      $html.find('.accordion-title').eq(0).should.have.attr('aria-expanded', 'false');
      $html.find('.accordion-title').eq(0).should.have.attr('aria-selected', 'false');
    });

    it('not closes the open container if allowAllClosed is false', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Accordion($html, {allowAllClosed: false});

      plugin.up($html.find('.accordion-content').eq(0));
      $html.find('.accordion-content').eq(0).should.be.visible;
      // Element has aria-hidden="false" not set if it has not been actively toggled so far
      // Therefor check if it has not aria-hidden="true"
      $html.find('.accordion-content').eq(0).should.not.have.attr('aria-hidden', 'true');
    });
  });

  describe('down()', function() {
    it('opens the targeted container', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Accordion($html, {});

      plugin.down($html.find('.accordion-content').eq(1));
      $html.find('.accordion-content').eq(1).should.be.visible;
      $html.find('.accordion-content').eq(1).should.have.attr('aria-hidden', 'false');
    });

    it('toggles attributes of title of the targeted container', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Accordion($html, {});

      plugin.down($html.find('.accordion-content').eq(1));
      $html.find('.accordion-title').eq(1).should.have.attr('aria-expanded', 'true');
      $html.find('.accordion-title').eq(1).should.have.attr('aria-selected', 'true');
    });

    it('closes open container if multiExpand is false', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Accordion($html, {multiExpand: false});

      plugin.down($html.find('.accordion-content').eq(1));
      $html.find('.accordion-content').eq(0).should.have.attr('aria-hidden', 'true');
      $html.on('up.zf.accordion', function() {
        $html.find('.accordion-content').eq(0).should.be.hidden;
        done();
      });
    });

    it('not closes open container if multiExpand is true', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Accordion($html, {multiExpand: true});

      plugin.down($html.find('.accordion-content').eq(1));
      $html.find('.accordion-content').eq(0).should.be.visible;
      // Element has aria-hidden="false" not set if it has not been actively toggled so far
      // Therefor check if it has not aria-hidden="true"
      $html.find('.accordion-content').eq(0).should.not.have.attr('aria-hidden', 'true');
    });
  });

  describe('toggle()', function(done) {
    it('closes the only open container if allowAllClosed is true', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Accordion($html, {allowAllClosed: true});

      plugin.toggle($html.find('.accordion-content').eq(0));
      $html.find('.accordion-content').eq(0).should.have.attr('aria-hidden', 'true');
      $html.on('up.zf.accordion', function() {
        $html.find('.accordion-content').eq(0).should.be.hidden;
        done();
      });
    });

    it('not closes the only open container if allowAllClosed is false', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Accordion($html, {allowAllClosed: false});

      plugin.toggle($html.find('.accordion-content').eq(0));
      $html.find('.accordion-content').eq(0).should.be.visible;
      $html.find('.accordion-content').eq(0).should.have.attr('aria-hidden', 'false');
    });
  });

  describe('keyboard events', function() {
    it('opens next panel on ARROW_DOWN', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Accordion($html, {});

      $html.find('.accordion-title').eq(0).focus()
        .trigger(window.mockKeyboardEvent('ARROW_DOWN'));

      $html.find('.accordion-content').eq(1).should.be.visible;
      $html.find('.accordion-content').eq(1).should.have.attr('aria-hidden', 'false');
      // Check if focus was moved
      $html.find('.accordion-title').eq(1)[0].should.be.equal(document.activeElement);
    });
    it('opens previous panel on ARROW_UP', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Accordion($html, {});

      $html.find('.accordion-title').eq(2).focus()
        .trigger(window.mockKeyboardEvent('ARROW_UP'));

      $html.find('.accordion-content').eq(1).should.be.visible;
      $html.find('.accordion-content').eq(1).should.have.attr('aria-hidden', 'false');
      // Check if focus was moved
      $html.find('.accordion-title').eq(1)[0].should.be.equal(document.activeElement);
    });
    it('opens related panel on ENTER', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Accordion($html, {});

      $html.find('.accordion-title').eq(1).focus()
        .trigger(window.mockKeyboardEvent('ENTER'));

      $html.find('.accordion-content').eq(1).should.be.visible;
      $html.find('.accordion-content').eq(1).should.have.attr('aria-hidden', 'false');
    });
    it('opens related panel on SPACE', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Accordion($html, {});

      $html.find('.accordion-title').eq(1).focus()
        .trigger(window.mockKeyboardEvent('SPACE'));

      $html.find('.accordion-content').eq(1).should.be.visible;
      $html.find('.accordion-content').eq(1).should.have.attr('aria-hidden', 'false');
    });
  });
});
