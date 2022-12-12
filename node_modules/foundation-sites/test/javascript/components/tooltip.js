describe('Tooltip', function() {
  var plugin;
  var $html;
  var template = `
    <span data-tooltip aria-haspopup="true" class="has-tip" tabindex="1" title="TOOLTIP_CONTENT">
      TEXT
    </span>`;
  Foundation.Tooltip.defaults.showOn = 'all';
  Foundation.Tooltip.defaults.fadeOutDuration = 0;
  Foundation.Tooltip.defaults.fadeInDuration = 0;

  afterEach(function() {
    plugin.destroy();
    $html.remove();
  });

  describe('constructor()', function() {
    it('stores the element and plugin options', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tooltip($html, {});

      plugin.$element.should.be.an('object');
      plugin.options.should.be.an('object');
    });
  });

  describe('init()', function() {

    it('has value of title attribute as content', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tooltip($html, {});

      plugin.template.text().should.equal('TOOLTIP_CONTENT');
    });

    it('has value of tipText option as content', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tooltip($html, {tipText: 'TOOLTIP_CONTENT_OPTION'});

      plugin.template.text().should.equal('TOOLTIP_CONTENT_OPTION');
    });

    it('uses value of template option as template', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tooltip($html, {template: '<div class="TEMPLATE_OPTION"></div>'});

      plugin.template.should.have.class('TEMPLATE_OPTION');
    });

    it('uses value of triggerClass option as trigger class', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tooltip($html, {triggerClass: 'TRIGGER_CLASS_OPTION'});

      plugin.$element.should.have.class('TRIGGER_CLASS_OPTION');
    });

    it('sets ARIA attributes', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tooltip($html, {});

      plugin.$element.should.have.attr('aria-describedby', plugin.template.attr('id'));
      plugin.template.should.have.attr('aria-hidden', 'true');
      plugin.template.should.have.attr('role', 'tooltip');
    });

  });

  describe('buildTemplate()', function() {
    it('uses value of templateClasses option as template class', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tooltip($html, {templateClasses: 'TOOLTIP_CLASS_OPTION'});

      plugin.template.should.have.class('TOOLTIP_CLASS_OPTION');
    });
  });

  describe('show()', function() {
    it('shows the tooltip', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tooltip($html, {});

      plugin.show();

      plugin.template.should.be.visible;
      plugin.template.should.have.attr('aria-hidden', 'false');
    });

    it('fires show.zf.tooltip event', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tooltip($html, {});

      $html.on('show.zf.tooltip', function() {
        plugin.template.should.be.visible;
        done();
      });

      plugin.show();
    });
  });

  describe('hide()', function() {
    it('hides the tooltip', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tooltip($html, {});

      // Show first
      plugin.show();

      plugin.hide();

      plugin.template.should.be.hidden;
      plugin.template.should.have.attr('aria-hidden', 'true');
    });

    it('fires hide.zf.tooltip event', function(done) {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tooltip($html, {});

      // Open it first
      plugin.show();

      $html.on('hide.zf.tooltip', function() {
        plugin.template.should.be.hidden;
        done();
      });

      plugin.hide();
    });
  });

  describe('toggle()', function() {
    it('shows a hidden tooltip', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tooltip($html, {});

      plugin.toggle();
      plugin.template.should.be.visible;
      plugin.template.should.have.attr('aria-hidden', 'false');
    });
    it('hides a visible tooltip', function() {
      $html = $(template).appendTo('body');
      plugin = new Foundation.Tooltip($html, {});

      // Show first
      plugin.show();

      plugin.toggle();
      plugin.template.should.be.hidden;
      plugin.template.should.have.attr('aria-hidden', 'true');
    });
  });

});