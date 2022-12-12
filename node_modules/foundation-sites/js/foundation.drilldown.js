'use strict';

import $ from 'jquery';
import { Keyboard } from './foundation.util.keyboard';
import { Nest } from './foundation.util.nest';
import { GetYoDigits, transitionend } from './foundation.core.utils';
import { Box } from './foundation.util.box';
import { Plugin } from './foundation.core.plugin';

/**
 * Drilldown module.
 * @module foundation.drilldown
 * @requires foundation.util.keyboard
 * @requires foundation.util.nest
 * @requires foundation.util.box
 */

class Drilldown extends Plugin {
  /**
   * Creates a new instance of a drilldown menu.
   * @class
   * @name Drilldown
   * @param {jQuery} element - jQuery object to make into an accordion menu.
   * @param {Object} options - Overrides to the default plugin settings.
   */
  _setup(element, options) {
    this.$element = element;
    this.options = $.extend({}, Drilldown.defaults, this.$element.data(), options);
    this.className = 'Drilldown'; // ie9 back compat

    this._init();

    Keyboard.register('Drilldown', {
      'ENTER': 'open',
      'SPACE': 'open',
      'ARROW_RIGHT': 'next',
      'ARROW_UP': 'up',
      'ARROW_DOWN': 'down',
      'ARROW_LEFT': 'previous',
      'ESCAPE': 'close',
      'TAB': 'down',
      'SHIFT_TAB': 'up'
    });
  }

  /**
   * Initializes the drilldown by creating jQuery collections of elements
   * @private
   */
  _init() {
    Nest.Feather(this.$element, 'drilldown');

    if(this.options.autoApplyClass) {
      this.$element.addClass('drilldown');
    }

    this.$element.attr({
      'role': 'tree',
      'aria-multiselectable': false
    });
    this.$submenuAnchors = this.$element.find('li.is-drilldown-submenu-parent').children('a');
    this.$submenus = this.$submenuAnchors.parent('li').children('[data-submenu]').attr('role', 'group');
    this.$menuItems = this.$element.find('li').not('.js-drilldown-back').attr('role', 'treeitem').find('a');

    // Set the main menu as current by default (unless a submenu is selected)
    // Used to set the wrapper height when the drilldown is closed/reopened from any (sub)menu
    this.$currentMenu = this.$element;

    this.$element.attr('data-mutate', (this.$element.attr('data-drilldown') || GetYoDigits(6, 'drilldown')));

    this._prepareMenu();
    this._registerEvents();

    this._keyboardEvents();
  }

  /**
   * prepares drilldown menu by setting attributes to links and elements
   * sets a min height to prevent content jumping
   * wraps the element if not already wrapped
   * @private
   * @function
   */
  _prepareMenu() {
    var _this = this;
    // if(!this.options.holdOpen){
    //   this._menuLinkEvents();
    // }
    this.$submenuAnchors.each(function(){
      var $link = $(this);
      var $sub = $link.parent();
      if(_this.options.parentLink){
        $link.clone().prependTo($sub.children('[data-submenu]')).wrap('<li data-is-parent-link class="is-submenu-parent-item is-submenu-item is-drilldown-submenu-item" role="menuitem"></li>');
      }
      $link.data('savedHref', $link.attr('href')).removeAttr('href').attr('tabindex', 0);
      $link.children('[data-submenu]')
          .attr({
            'aria-hidden': true,
            'tabindex': 0,
            'role': 'group'
          });
      _this._events($link);
    });
    this.$submenus.each(function(){
      var $menu = $(this),
          $back = $menu.find('.js-drilldown-back');
      if(!$back.length){
        switch (_this.options.backButtonPosition) {
          case "bottom":
            $menu.append(_this.options.backButton);
            break;
          case "top":
            $menu.prepend(_this.options.backButton);
            break;
          default:
            console.error("Unsupported backButtonPosition value '" + _this.options.backButtonPosition + "'");
        }
      }
      _this._back($menu);
    });

    this.$submenus.addClass('invisible');
    if(!this.options.autoHeight) {
      this.$submenus.addClass('drilldown-submenu-cover-previous');
    }

    // create a wrapper on element if it doesn't exist.
    if(!this.$element.parent().hasClass('is-drilldown')){
      this.$wrapper = $(this.options.wrapper).addClass('is-drilldown');
      if(this.options.animateHeight) this.$wrapper.addClass('animate-height');
      this.$element.wrap(this.$wrapper);
    }
    // set wrapper
    this.$wrapper = this.$element.parent();
    this.$wrapper.css(this._getMaxDims());
  }

  _resize() {
    this.$wrapper.css({'max-width': 'none', 'min-height': 'none'});
    // _getMaxDims has side effects (boo) but calling it should update all other necessary heights & widths
    this.$wrapper.css(this._getMaxDims());
  }

  /**
   * Adds event handlers to elements in the menu.
   * @function
   * @private
   * @param {jQuery} $elem - the current menu item to add handlers to.
   */
  _events($elem) {
    var _this = this;

    $elem.off('click.zf.drilldown')
    .on('click.zf.drilldown', function(e){
      if($(e.target).parentsUntil('ul', 'li').hasClass('is-drilldown-submenu-parent')){
        e.stopImmediatePropagation();
        e.preventDefault();
      }

      // if(e.target !== e.currentTarget.firstElementChild){
      //   return false;
      // }
      _this._show($elem.parent('li'));

      if(_this.options.closeOnClick){
        var $body = $('body');
        $body.off('.zf.drilldown').on('click.zf.drilldown', function(e){
          if (e.target === _this.$element[0] || $.contains(_this.$element[0], e.target)) { return; }
          e.preventDefault();
          _this._hideAll();
          $body.off('.zf.drilldown');
        });
      }
    });
  }

  /**
   * Adds event handlers to the menu element.
   * @function
   * @private
   */
  _registerEvents() {
    if(this.options.scrollTop){
      this._bindHandler = this._scrollTop.bind(this);
      this.$element.on('open.zf.drilldown hide.zf.drilldown closed.zf.drilldown',this._bindHandler);
    }
    this.$element.on('mutateme.zf.trigger', this._resize.bind(this));
  }

  /**
   * Scroll to Top of Element or data-scroll-top-element
   * @function
   * @fires Drilldown#scrollme
   */
  _scrollTop() {
    var _this = this;
    var $scrollTopElement = _this.options.scrollTopElement!=''?$(_this.options.scrollTopElement):_this.$element,
        scrollPos = parseInt($scrollTopElement.offset().top+_this.options.scrollTopOffset, 10);
    $('html, body').stop(true).animate({ scrollTop: scrollPos }, _this.options.animationDuration, _this.options.animationEasing,function(){
      /**
        * Fires after the menu has scrolled
        * @event Drilldown#scrollme
        */
      if(this===$('html')[0])_this.$element.trigger('scrollme.zf.drilldown');
    });
  }

  /**
   * Adds keydown event listener to `li`'s in the menu.
   * @private
   */
  _keyboardEvents() {
    var _this = this;

    this.$menuItems.add(this.$element.find('.js-drilldown-back > a, .is-submenu-parent-item > a')).on('keydown.zf.drilldown', function(e){
      var $element = $(this),
          $elements = $element.parent('li').parent('ul').children('li').children('a'),
          $prevElement,
          $nextElement;

      $elements.each(function(i) {
        if ($(this).is($element)) {
          $prevElement = $elements.eq(Math.max(0, i-1));
          $nextElement = $elements.eq(Math.min(i+1, $elements.length-1));
          return;
        }
      });

      Keyboard.handleKey(e, 'Drilldown', {
        next: function() {
          if ($element.is(_this.$submenuAnchors)) {
            _this._show($element.parent('li'));
            $element.parent('li').one(transitionend($element), function(){
              $element.parent('li').find('ul li a').not('.js-drilldown-back a').first().focus();
            });
            return true;
          }
        },
        previous: function() {
          _this._hide($element.parent('li').parent('ul'));
          $element.parent('li').parent('ul').one(transitionend($element), function(){
            setTimeout(function() {
              $element.parent('li').parent('ul').parent('li').children('a').first().focus();
            }, 1);
          });
          return true;
        },
        up: function() {
          $prevElement.focus();
          // Don't tap focus on first element in root ul
          return !$element.is(_this.$element.find('> li:first-child > a'));
        },
        down: function() {
          $nextElement.focus();
          // Don't tap focus on last element in root ul
          return !$element.is(_this.$element.find('> li:last-child > a'));
        },
        close: function() {
          // Don't close on element in root ul
          if (!$element.is(_this.$element.find('> li > a'))) {
            _this._hide($element.parent().parent());
            $element.parent().parent().siblings('a').focus();
          }
        },
        open: function() {
          if (_this.options.parentLink && $element.attr('href')) { // Link with href
            return false;
          } else if (!$element.is(_this.$menuItems)) { // not menu item means back button
            _this._hide($element.parent('li').parent('ul'));
            $element.parent('li').parent('ul').one(transitionend($element), function(){
              setTimeout(function() {
                $element.parent('li').parent('ul').parent('li').children('a').first().focus();
              }, 1);
            });
            return true;
          } else if ($element.is(_this.$submenuAnchors)) { // Sub menu item
            _this._show($element.parent('li'));
            $element.parent('li').one(transitionend($element), function(){
              $element.parent('li').find('ul li a').not('.js-drilldown-back a').first().focus();
            });
            return true;
          }
        },
        handled: function(preventDefault) {
          if (preventDefault) {
            e.preventDefault();
          }
          e.stopImmediatePropagation();
        }
      });
    }); // end keyboardAccess
  }

  /**
   * Closes all open elements, and returns to root menu.
   * @function
   * @fires Drilldown#closed
   */
  _hideAll() {
    var $elem = this.$element.find('.is-drilldown-submenu.is-active').addClass('is-closing');
    if(this.options.autoHeight) this.$wrapper.css({height:$elem.parent().closest('ul').data('calcHeight')});
    $elem.one(transitionend($elem), function(e){
      $elem.removeClass('is-active is-closing');
    });
        /**
         * Fires when the menu is fully closed.
         * @event Drilldown#closed
         */
    this.$element.trigger('closed.zf.drilldown');
  }

  /**
   * Adds event listener for each `back` button, and closes open menus.
   * @function
   * @fires Drilldown#back
   * @param {jQuery} $elem - the current sub-menu to add `back` event.
   */
  _back($elem) {
    var _this = this;
    $elem.off('click.zf.drilldown');
    $elem.children('.js-drilldown-back')
      .on('click.zf.drilldown', function(e){
        e.stopImmediatePropagation();
        // console.log('mouseup on back');
        _this._hide($elem);

        // If there is a parent submenu, call show
        let parentSubMenu = $elem.parent('li').parent('ul').parent('li');
        if (parentSubMenu.length) {
          _this._show(parentSubMenu);
        }
      });
  }

  /**
   * Adds event listener to menu items w/o submenus to close open menus on click.
   * @function
   * @private
   */
  _menuLinkEvents() {
    var _this = this;
    this.$menuItems.not('.is-drilldown-submenu-parent')
        .off('click.zf.drilldown')
        .on('click.zf.drilldown', function(e){
          // e.stopImmediatePropagation();
          setTimeout(function(){
            _this._hideAll();
          }, 0);
      });
  }

  /**
   * Sets the CSS classes for submenu to show it.
   * @function
   * @private
   * @param {jQuery} $elem - the target submenu (`ul` tag)
   * @param {boolean} trigger - trigger drilldown event
   */
  _setShowSubMenuClasses($elem, trigger) {
    $elem.addClass('is-active').removeClass('invisible').attr('aria-hidden', false);
    $elem.parent('li').attr('aria-expanded', true);
    if (trigger === true) {
      this.$element.trigger('open.zf.drilldown', [$elem]);
    }
  }

  /**
   * Sets the CSS classes for submenu to hide it.
   * @function
   * @private
   * @param {jQuery} $elem - the target submenu (`ul` tag)
   * @param {boolean} trigger - trigger drilldown event
   */
  _setHideSubMenuClasses($elem, trigger) {
    $elem.removeClass('is-active').addClass('invisible').attr('aria-hidden', true);
    $elem.parent('li').attr('aria-expanded', false);
    if (trigger === true) {
      $elem.trigger('hide.zf.drilldown', [$elem]);
    }
  }

  /**
   * Opens a specific drilldown (sub)menu no matter which (sub)menu in it is currently visible.
   * Compared to _show() this lets you jump into any submenu without clicking through every submenu on the way to it.
   * @function
   * @fires Drilldown#open
   * @param {jQuery} $elem - the target (sub)menu (`ul` tag)
   * @param {boolean} autoFocus - if true the first link in the target (sub)menu gets auto focused
   */
  _showMenu($elem, autoFocus) {

    var _this = this;

    // Reset drilldown
    var $expandedSubmenus = this.$element.find('li[aria-expanded="true"] > ul[data-submenu]');
    $expandedSubmenus.each(function(index) {
      _this._setHideSubMenuClasses($(this));
    });

    // Save the menu as the currently displayed one.
    this.$currentMenu = $elem;

    // If target menu is root, focus first link & exit
    if ($elem.is('[data-drilldown]')) {
      if (autoFocus === true) $elem.find('li[role="treeitem"] > a').first().focus();
      if (this.options.autoHeight) this.$wrapper.css('height', $elem.data('calcHeight'));
      return;
    }

    // Find all submenus on way to root incl. the element itself
    var $submenus = $elem.children().first().parentsUntil('[data-drilldown]', '[data-submenu]');

    // Open target menu and all submenus on its way to root
    $submenus.each(function(index) {

      // Update height of first child (target menu) if autoHeight option true
      if (index === 0 && _this.options.autoHeight) {
        _this.$wrapper.css('height', $(this).data('calcHeight'));
      }

      var isLastChild = index == $submenus.length - 1;

      // Add transitionsend listener to last child (root due to reverse order) to open target menu's first link
      // Last child makes sure the event gets always triggered even if going through several menus
      if (isLastChild === true) {
        $(this).one(transitionend($(this)), () => {
          if (autoFocus === true) {
            $elem.find('li[role="treeitem"] > a').first().focus();
          }
        });
      }

      _this._setShowSubMenuClasses($(this), isLastChild);
    });
  }

  /**
   * Opens a submenu.
   * @function
   * @fires Drilldown#open
   * @param {jQuery} $elem - the current element with a submenu to open, i.e. the `li` tag.
   */
  _show($elem) {
    const $submenu = $elem.children('[data-submenu]');

    $elem.attr('aria-expanded', true);

    this.$currentMenu = $submenu;
    $submenu.addClass('is-active').removeClass('invisible').attr('aria-hidden', false);
    if (this.options.autoHeight) {
      this.$wrapper.css({ height: $submenu.data('calcHeight') });
    }

    /**
     * Fires when the submenu has opened.
     * @event Drilldown#open
     */
    this.$element.trigger('open.zf.drilldown', [$elem]);
  }

  /**
   * Hides a submenu
   * @function
   * @fires Drilldown#hide
   * @param {jQuery} $elem - the current sub-menu to hide, i.e. the `ul` tag.
   */
  _hide($elem) {
    if(this.options.autoHeight) this.$wrapper.css({height:$elem.parent().closest('ul').data('calcHeight')});
    var _this = this;
    $elem.parent('li').attr('aria-expanded', false);
    $elem.attr('aria-hidden', true);
    $elem.addClass('is-closing')
         .one(transitionend($elem), function(){
           $elem.removeClass('is-active is-closing');
           $elem.blur().addClass('invisible');
         });
    /**
     * Fires when the submenu has closed.
     * @event Drilldown#hide
     */
    $elem.trigger('hide.zf.drilldown', [$elem]);
  }

  /**
   * Iterates through the nested menus to calculate the min-height, and max-width for the menu.
   * Prevents content jumping.
   * @function
   * @private
   */
  _getMaxDims() {
    var maxHeight = 0, result = {}, _this = this;

    // Recalculate menu heights and total max height
    this.$submenus.add(this.$element).each(function(){
      var numOfElems = $(this).children('li').length;
      var height = Box.GetDimensions(this).height;

      maxHeight = height > maxHeight ? height : maxHeight;

      if(_this.options.autoHeight) {
        $(this).data('calcHeight',height);
      }
    });

    if (this.options.autoHeight)
      result['height'] = this.$currentMenu.data('calcHeight');
    else
      result['min-height'] = `${maxHeight}px`;

    result['max-width'] = `${this.$element[0].getBoundingClientRect().width}px`;

    return result;
  }

  /**
   * Destroys the Drilldown Menu
   * @function
   */
  _destroy() {
    if(this.options.scrollTop) this.$element.off('.zf.drilldown',this._bindHandler);
    this._hideAll();
	  this.$element.off('mutateme.zf.trigger');
    Nest.Burn(this.$element, 'drilldown');
    this.$element.unwrap()
                 .find('.js-drilldown-back, .is-submenu-parent-item').remove()
                 .end().find('.is-active, .is-closing, .is-drilldown-submenu').removeClass('is-active is-closing is-drilldown-submenu')
                 .end().find('[data-submenu]').removeAttr('aria-hidden tabindex role');
    this.$submenuAnchors.each(function() {
      $(this).off('.zf.drilldown');
    });

    this.$element.find('[data-is-parent-link]').detach();
    this.$submenus.removeClass('drilldown-submenu-cover-previous invisible');

    this.$element.find('a').each(function(){
      var $link = $(this);
      $link.removeAttr('tabindex');
      if($link.data('savedHref')){
        $link.attr('href', $link.data('savedHref')).removeData('savedHref');
      }else{ return; }
    });
  };
}

Drilldown.defaults = {
  /**
   * Drilldowns depend on styles in order to function properly; in the default build of Foundation these are
   * on the `drilldown` class. This option auto-applies this class to the drilldown upon initialization.
   * @option
   * @type {boolian}
   * @default true
   */
  autoApplyClass: true,
  /**
   * Markup used for JS generated back button. Prepended  or appended (see backButtonPosition) to submenu lists and deleted on `destroy` method, 'js-drilldown-back' class required. Remove the backslash (`\`) if copy and pasting.
   * @option
   * @type {string}
   * @default '<li class="js-drilldown-back"><a tabindex="0">Back</a></li>'
   */
  backButton: '<li class="js-drilldown-back"><a tabindex="0">Back</a></li>',
  /**
   * Position the back button either at the top or bottom of drilldown submenus. Can be `'left'` or `'bottom'`.
   * @option
   * @type {string}
   * @default top
   */
  backButtonPosition: 'top',
  /**
   * Markup used to wrap drilldown menu. Use a class name for independent styling; the JS applied class: `is-drilldown` is required. Remove the backslash (`\`) if copy and pasting.
   * @option
   * @type {string}
   * @default '<div></div>'
   */
  wrapper: '<div></div>',
  /**
   * Adds the parent link to the submenu.
   * @option
   * @type {boolean}
   * @default false
   */
  parentLink: false,
  /**
   * Allow the menu to return to root list on body click.
   * @option
   * @type {boolean}
   * @default false
   */
  closeOnClick: false,
  /**
   * Allow the menu to auto adjust height.
   * @option
   * @type {boolean}
   * @default false
   */
  autoHeight: false,
  /**
   * Animate the auto adjust height.
   * @option
   * @type {boolean}
   * @default false
   */
  animateHeight: false,
  /**
   * Scroll to the top of the menu after opening a submenu or navigating back using the menu back button
   * @option
   * @type {boolean}
   * @default false
   */
  scrollTop: false,
  /**
   * String jquery selector (for example 'body') of element to take offset().top from, if empty string the drilldown menu offset().top is taken
   * @option
   * @type {string}
   * @default ''
   */
  scrollTopElement: '',
  /**
   * ScrollTop offset
   * @option
   * @type {number}
   * @default 0
   */
  scrollTopOffset: 0,
  /**
   * Scroll animation duration
   * @option
   * @type {number}
   * @default 500
   */
  animationDuration: 500,
  /**
   * Scroll animation easing. Can be `'swing'` or `'linear'`.
   * @option
   * @type {string}
   * @see {@link https://api.jquery.com/animate|JQuery animate}
   * @default 'swing'
   */
  animationEasing: 'swing'
  // holdOpen: false
};

export {Drilldown};
