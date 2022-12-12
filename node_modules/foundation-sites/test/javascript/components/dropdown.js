describe('Dropdown', function() {
  let plugin;
  let $dropdownController;
  let $dropdownContainer;

  const getDropdownController = (buttonClasses = '') =>
    `<button class="${buttonClasses}" type="button" data-toggle="my-dropdown">toggle</button>`;
  const getDropdownContainer = (dropdownClasses = '') =>
    `<div class="${dropdownClasses}" data-dropdown id="my-dropdown">Dropdown</div>`;
  const getFocusableDropdownContainer = (dropdownClasses = '', inputId = '') =>
    `<div class="${dropdownClasses}" data-dropdown id="my-dropdown">Dropdown${getFocusableInput(inputId)}</div>`;

  const getFocusableInput = (inputId = '') =>
    `<input type="text" placeholder="should auto focus" id="${inputId}" />`;
  const getAutoFocusDropdownContainer = (dropdownClasses = '', inputId = '') =>
    `<div class="${dropdownClasses}" data-dropdown data-auto-focus="true" id="my-dropdown">Dropdown${getFocusableInput(inputId)}</div>`;

  afterEach(function() {
    plugin.destroy();
    document.activeElement.blur();
    $dropdownController.remove();
    $dropdownContainer.remove();
  });

  describe('constructor()', function() {
    it('stores the element & plugin options', function() {
      $dropdownController = $(getDropdownController()).appendTo('body');
      $dropdownContainer = $(getDropdownContainer()).appendTo('body');
      plugin = new Foundation.Dropdown($dropdownContainer, {});

      plugin.$element.should.be.an('object');
      plugin.options.should.be.an('object');
    });
  });

  describe('open()', function () {
    it('fires show.zf.dropdown event', function () {
      $dropdownController = $(getDropdownController()).appendTo('body');
      $dropdownContainer = $(getDropdownContainer()).appendTo('body');
      plugin = new Foundation.Dropdown($dropdownContainer, {});

      let spy = sinon.spy();
      $dropdownContainer.on('show.zf.dropdown', spy);

      plugin.open();

      sinon.assert.called(spy);
    });

    it('make the dropdown visible', function (done) {
      $dropdownController = $(getDropdownController()).appendTo('body');
      $dropdownContainer = $(getDropdownContainer()).appendTo('body');
      plugin = new Foundation.Dropdown($dropdownContainer, {});

      $dropdownContainer.on('show.zf.dropdown', function () {
        $('#my-dropdown').should.not.be.hidden;
        $('#my-dropdown').should.have.attr('aria-hidden', 'false');
        $('#my-dropdown').should.have.class('is-open');
        done();
      });
      plugin.open();
    });

    it('traps focus accoding to trapFocus option', function () {
      $dropdownController = $(getDropdownController()).appendTo('body');
      $dropdownContainer = $(getDropdownContainer()).appendTo('body');
      plugin = new Foundation.Dropdown($dropdownContainer, { trapFocus: true });

      let spy = sinon.spy(Foundation.Keyboard, 'trapFocus');
      plugin.open();

      sinon.assert.called(spy);
      Foundation.Keyboard.trapFocus.restore();
    });

    it('should autofocus according to autoFocus option', function(done) {
      $dropdownController = $(getDropdownController()).appendTo('body');
      $dropdownContainer = $(getAutoFocusDropdownContainer('', 'inputToFocus')).appendTo('body');
      plugin = new Foundation.Dropdown($dropdownContainer, { autoFocus: true });

      $dropdownContainer.on('show.zf.dropdown', function() {
        document.activeElement.id.should.be.equal('inputToFocus');
        done();
      });
      plugin.open();
    });
  });

  describe('close()', function() {
    it('releases focus if trapFocus option is true', function() {
      $dropdownController = $(getDropdownController()).appendTo('body');
      $dropdownContainer = $(getDropdownContainer()).appendTo('body');
      plugin = new Foundation.Dropdown($dropdownContainer, {trapFocus: true});

      // Open it first...
      plugin.open();

      let spy = sinon.spy(Foundation.Keyboard, 'releaseFocus');
      plugin.close();

      sinon.assert.called(spy);
      Foundation.Keyboard.releaseFocus.restore();
    });
  });

  describe('inferred positioning', function() {
    it('default orientation should be bottom', function() {
      $dropdownController = $(getDropdownController()).appendTo('body');
      $dropdownContainer = $(getDropdownContainer()).appendTo('body');
      plugin = new Foundation.Dropdown($dropdownContainer, {});

      plugin.open()
      plugin.position.should.equal('bottom');
    });

    it('gets right alignment from float-right', function() {
      $dropdownController = $(getDropdownController('custom-style-before float-right custom-style-after'))
        .appendTo('body');
      $dropdownContainer = $(getDropdownContainer()).appendTo('body');
      plugin = new Foundation.Dropdown($dropdownContainer, {});

      plugin.open()
      plugin.position.should.equal('bottom')
      plugin.alignment.should.equal('right')
    });
  });

  describe('closeOnClick option', function() {
    it('not closes a dropdown by clicking on the dropdown if closeOnClick option is true', function(done) {
      $dropdownController = $(getDropdownController()).appendTo('body');
      $dropdownContainer = $(getDropdownContainer()).appendTo('body');
      plugin = new Foundation.Dropdown($dropdownContainer, {closeOnClick: true});

      // Open it first...
      plugin.open();

      let spy = sinon.spy(plugin, 'close');
      plugin.$element.trigger('click');

      setTimeout(() => {
        sinon.assert.notCalled(spy);
        done();
      }, 0);
    });
  });

  describe('mouse events', function() {
    it('opens the dropdown on button click', function(done) {
      $dropdownController = $(getDropdownController()).appendTo('body');
      $dropdownContainer = $(getDropdownContainer()).appendTo('body');
      plugin = new Foundation.Dropdown($dropdownContainer, {});

      let spy = sinon.spy(plugin, 'open');
      $dropdownController.trigger('click');

      setTimeout(() => {
        sinon.assert.called(spy);
        done();
      }, 0);
    });

    it('opens the dropdown on button hover', function(done) {
      $dropdownController = $(getDropdownController()).appendTo('body');
      $dropdownContainer = $(getDropdownContainer()).appendTo('body');
      plugin = new Foundation.Dropdown($dropdownContainer, { hover: true, hoverDelay: 42 });

      let spy = sinon.spy(plugin, 'open');
      $dropdownController.trigger('mouseenter');

      setTimeout(() => {
        sinon.assert.called(spy);
        done();
      }, 42);
    });

  });

  describe('keyboard events', function () {
    it('opens Dropdown on SPACE', function() {
      $dropdownController = $(getDropdownController()).appendTo('body');
      $dropdownContainer = $(getDropdownContainer()).appendTo('body');
      plugin = new Foundation.Dropdown($dropdownContainer, {});
      $dropdownController.focus()
        .trigger(window.mockKeyboardEvent('SPACE'));

      $dropdownContainer.should.be.visible;
    });
    it('does not focus Dropdown on SPACE by default', function() {
      $dropdownController = $(getDropdownController()).appendTo('body');
      $dropdownContainer = $(getDropdownContainer()).appendTo('body');
      plugin = new Foundation.Dropdown($dropdownContainer, {});
      $dropdownController.focus()
        .trigger(window.mockKeyboardEvent('SPACE'));

      document.activeElement.should.be.equal($dropdownController[0]);
    });
    it('focuses Dropdown on SPACE when container has a focusable element', function() {
      $dropdownController = $(getDropdownController()).appendTo('body');
      $dropdownContainer = $(getFocusableDropdownContainer()).appendTo('body');
      plugin = new Foundation.Dropdown($dropdownContainer, {});
      $dropdownController.focus()
        .trigger(window.mockKeyboardEvent('SPACE'));

      document.activeElement.should.be.equal($dropdownController[0]);
    });
    it('does not focus Dropdown when anchor is an input', function() {
      $dropdownController = $('<input type="text" data-toggle="my-dropdown">').appendTo('body');
      $dropdownContainer = $(getDropdownContainer()).appendTo('body');
      plugin = new Foundation.Dropdown($dropdownContainer, {});
      $dropdownController.focus()
        .trigger(window.mockKeyboardEvent('SPACE'));

      document.activeElement.should.be.equal($dropdownController[0]);
    });
  })
});
