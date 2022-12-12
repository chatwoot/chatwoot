describe('Dropdown Menu', function () {
  var plugin;
  var $html;
  var template = `<ul class="dropdown menu" data-dropdown-menu>
    <li>
      <a href="#Item-1">Item 1</a>
      <ul class="menu">
      <li><a href="#Item-1A">Item 1A</a></li>
      <li>
        <a href="#Item-1B">Item 1B</a>
        <ul class="menu">
        <li><a href="#Item-1Bi">Item 1B i</a></li>
        <li><a href="#Item-1Bii">Item 1B ii</a></li>
        <li>
          <a href="#Item-1Biii">Item 1B iii</a>
          <ul class="menu">
          <li><a href="#Item-1Biiialpha">Item 1B iii alpha</a></li>
          <li><a href="#Item-1Biiiomega">Item 1B iii omega</a></li>
          </ul>
        </li>
        <li>
          <a href="#Item-1Biv">Item 1B iv</a>
          <ul class="menu">
          <li><a href="#Item-1Bivalpha">Item 1B iv alpha</a></li>
          </ul>
        </li>
        </ul>
      </li>
      <li><a href="#Item-1C">Item 1C</a></li>
      </ul>
    </li>
    <li>
      <a href="#Item-2">Item 2</a>
      <ul class="menu">
      <li><a href="#Item-2A">Item 2A</a></li>
      <li><a href="#Item-2B">Item 2B</a></li>
      </ul>
    </li>
    <li><a href="#Item-3">Item 3</a></li>
    <li><a href="#Item-4">Item 4</a></li>
  </ul>`;

  afterEach(function () {
    plugin.destroy();
    document.activeElement.blur();
    $html.remove();
  });

  describe('constructor()', function () {
    it('stores the element and plugin options', function () {
      $html = $(template).appendTo('body');
      plugin = new Foundation.DropdownMenu($html, {});

      plugin.$element.should.be.an('object');
      plugin.options.should.be.an('object');
    });
  });

  /*
  ** Note: for all the following tests testing the currently focused elements,
  ** IE 9/10/11 may not focus the tested element because is is still rendering.
  ** To prevent this, we wait after the component initialization.
  **
  ** Fixing this IE behavior in components would require to delay the focus
  ** for all browsers then trigger a "ready" event.
  **
  ** TODO: Consider this for v6.6
  **
  ** See https://stackoverflow.com/a/2600261/4317384
  ** See https://stackoverflow.com/a/36032615/4317384
  */
  const IErenderWaitTime = 100;

  describe('keyboard events', function () {

    it('closes current sub menu using ESCAPE', function (done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.DropdownMenu($html, {});

      setTimeout(() => {
        // Open it first
        plugin._show($html.find('> li:nth-child(1) > ul'));

        $html.find('> li:nth-child(1) > ul > li:nth-child(1) > a').focus()
          .trigger(window.mockKeyboardEvent('ESCAPE'));

        $html.find('> li:nth-child(1)').should.not.have.class('is-active');
        $html.find('> li:nth-child(1) > ul').should.not.have.class('js-dropdown-active');
        document.activeElement.should.be.equal($html.find('> li:nth-child(1) > a')[0]);
        done();
      }, IErenderWaitTime);
    });

    describe('horizontal', function() {
      beforeEach(function(done) {
        $html = $(template).appendTo('body');
        plugin = new Foundation.DropdownMenu($html, {});
        setTimeout(() => done(), IErenderWaitTime);
      });

      it('moves focus to next tab on ARROW_RIGHT', function () {
          $html.find('> li:nth-child(1) > a').focus()
            .trigger(window.mockKeyboardEvent('ARROW_RIGHT'));

          document.activeElement.should.be.equal($html.find('> li:nth-child(2) > a')[0]);
      });

      it('moves focus to previous tab on ARROW_LEFT', function () {
        $html.find('> li:nth-child(2) > a').focus()
          .trigger(window.mockKeyboardEvent('ARROW_LEFT'));

        document.activeElement.should.be.equal($html.find('> li:nth-child(1) > a')[0]);
      });

      it('opens child element of tab on ARROW_DOWN', function() {
        $html.find('> li:nth-child(1) > a').focus()
          .trigger(window.mockKeyboardEvent('ARROW_DOWN'));

        $html.find('> li:nth-child(1)').should.have.class('is-active');
        $html.find('> li:nth-child(1) > ul').should.have.class('js-dropdown-active');
        document.activeElement.should.be.equal($html.find('> li:nth-child(1) > ul > li:nth-child(1) > a')[0]);
      });

      it('moves focus to previous sub element on ARROW_UP', function () {
        // Open it first
        plugin._show($html.find('> li:nth-child(1) > ul'));

        $html.find('> li:nth-child(1) > ul > li:nth-child(2) > a').focus()
          .trigger(window.mockKeyboardEvent('ARROW_UP'));

        document.activeElement.should.be.equal($html.find('> li:nth-child(1) > ul > li:nth-child(1) > a')[0]);
      });

      it('opens child element of sub menu on ARROW_RIGHT', function() {
        // Open it first
        plugin._show($html.find('> li:nth-child(1) > ul'));

        $html.find('> li:nth-child(1) > ul > li:nth-child(2) > a').focus()
          .trigger(window.mockKeyboardEvent('ARROW_RIGHT'));

        $html.find('> li:nth-child(1) > ul > li:nth-child(2)').should.have.class('is-active');
        $html.find('> li:nth-child(1) > ul > li:nth-child(2) > ul').should.have.class('js-dropdown-active');
        document.activeElement.should.be.equal($html.find('> li:nth-child(1) > ul > li:nth-child(2) > ul > li:nth-child(1) > a')[0]);
      });

    });

    describe('vertical', function () {

      beforeEach(function(done) {
        $html = $(template).addClass('vertical').appendTo('body');
        plugin = new Foundation.DropdownMenu($html, {});
        setTimeout(() => done(), IErenderWaitTime);
      });

      it('moves focus to next tab on ARROW_DOWN', function () {
        $html.find('> li:nth-child(1) > a').focus()
          .trigger(window.mockKeyboardEvent('ARROW_DOWN'));

        document.activeElement.should.be.equal($html.find('> li:nth-child(2) > a')[0]);
      });

      it('moves focus to previous tab on ARROW_UP', function () {
        $html.find('> li:nth-child(2) > a').focus()
          .trigger(window.mockKeyboardEvent('ARROW_UP'));

        document.activeElement.should.be.equal($html.find('> li:nth-child(1) > a')[0]);
      });

      it('opens child element of tab on ARROW_RIGHT', function() {
        $html.find('> li:nth-child(1) > a').focus()
          .trigger(window.mockKeyboardEvent('ARROW_RIGHT'));

        $html.find('> li:nth-child(1)').should.have.class('is-active');
        $html.find('> li:nth-child(1) > ul').should.have.class('js-dropdown-active');
        document.activeElement.should.be.equal($html.find('> li:nth-child(1) > ul > li:nth-child(1) > a')[0]);
      });

      it('moves focus to previous sub element on ARROW_UP', function () {
        // Open it first
        plugin._show($html.find('> li:nth-child(1) > ul'));

        $html.find('> li:nth-child(1) > ul > li:nth-child(2) > a').focus()
          .trigger(window.mockKeyboardEvent('ARROW_UP'));

        document.activeElement.should.be.equal($html.find('> li:nth-child(1) > ul > li:nth-child(1) > a')[0]);
      });

      it('opens child element of sub menu on ARROW_RIGHT', function() {
        // Open it first
        plugin._show($html.find('> li:nth-child(1) > ul'));

        $html.find('> li:nth-child(1) > ul > li:nth-child(2) > a').focus()
          .trigger(window.mockKeyboardEvent('ARROW_RIGHT'));

        $html.find('> li:nth-child(1) > ul > li:nth-child(2)').should.have.class('is-active');
        $html.find('> li:nth-child(1) > ul > li:nth-child(2) > ul').should.have.class('js-dropdown-active');
        document.activeElement.should.be.equal($html.find('> li:nth-child(1) > ul > li:nth-child(2) > ul > li:nth-child(1) > a')[0]);
      });

    });

  });

});
