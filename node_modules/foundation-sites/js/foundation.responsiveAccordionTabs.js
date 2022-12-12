'use strict';

import $ from 'jquery';
import { MediaQuery } from './foundation.util.mediaQuery';
import { GetYoDigits } from './foundation.core.utils';
import { Plugin }from './foundation.core.plugin';

import { Accordion } from './foundation.accordion';
import { Tabs } from './foundation.tabs';

// The plugin matches the plugin classes with these plugin instances.
var MenuPlugins = {
  tabs: {
    cssClass: 'tabs',
    plugin: Tabs
  },
  accordion: {
    cssClass: 'accordion',
    plugin: Accordion
  }
};


/**
 * ResponsiveAccordionTabs module.
 * @module foundation.responsiveAccordionTabs
 * @requires foundation.util.motion
 * @requires foundation.accordion
 * @requires foundation.tabs
 */

class ResponsiveAccordionTabs extends Plugin{
  /**
   * Creates a new instance of a responsive accordion tabs.
   * @class
   * @name ResponsiveAccordionTabs
   * @fires ResponsiveAccordionTabs#init
   * @param {jQuery} element - jQuery object to make into Responsive Accordion Tabs.
   * @param {Object} options - Overrides to the default plugin settings.
   */
  _setup(element, options) {
    this.$element = $(element);
    this.options  = $.extend({}, this.$element.data(), options);
    this.rules = this.$element.data('responsive-accordion-tabs');
    this.currentMq = null;
    this.currentPlugin = null;
    this.className = 'ResponsiveAccordionTabs'; // ie9 back compat
    if (!this.$element.attr('id')) {
      this.$element.attr('id',GetYoDigits(6, 'responsiveaccordiontabs'));
    };

    this._init();
    this._events();
  }

  /**
   * Initializes the Menu by parsing the classes from the 'data-responsive-accordion-tabs' attribute on the element.
   * @function
   * @private
   */
  _init() {
    MediaQuery._init();

    // The first time an Interchange plugin is initialized, this.rules is converted from a string of "classes" to an object of rules
    if (typeof this.rules === 'string') {
      let rulesTree = {};

      // Parse rules from "classes" pulled from data attribute
      let rules = this.rules.split(' ');

      // Iterate through every rule found
      for (let i = 0; i < rules.length; i++) {
        let rule = rules[i].split('-');
        let ruleSize = rule.length > 1 ? rule[0] : 'small';
        let rulePlugin = rule.length > 1 ? rule[1] : rule[0];

        if (MenuPlugins[rulePlugin] !== null) {
          rulesTree[ruleSize] = MenuPlugins[rulePlugin];
        }
      }

      this.rules = rulesTree;
    }

    this._getAllOptions();

    if (!$.isEmptyObject(this.rules)) {
      this._checkMediaQueries();
    }
  }

  _getAllOptions() {
    //get all defaults and options
    var _this = this;
    _this.allOptions = {};
    for (var key in MenuPlugins) {
      if (MenuPlugins.hasOwnProperty(key)) {
        var obj = MenuPlugins[key];
        try {
          var dummyPlugin = $('<ul></ul>');
          var tmpPlugin = new obj.plugin(dummyPlugin,_this.options);
          for (var keyKey in tmpPlugin.options) {
            if (tmpPlugin.options.hasOwnProperty(keyKey) && keyKey !== 'zfPlugin') {
              var objObj = tmpPlugin.options[keyKey];
              _this.allOptions[keyKey] = objObj;
            }
          }
          tmpPlugin.destroy();
        }
        catch(e) {
        }
      }
    }
  }

  /**
   * Initializes events for the Menu.
   * @function
   * @private
   */
  _events() {
    this._changedZfMediaQueryHandler = this._checkMediaQueries.bind(this);
    $(window).on('changed.zf.mediaquery', this._changedZfMediaQueryHandler);
  }

  /**
   * Checks the current screen width against available media queries. If the media query has changed, and the plugin needed has changed, the plugins will swap out.
   * @function
   * @private
   */
  _checkMediaQueries() {
    var matchedMq, _this = this;
    // Iterate through each rule and find the last matching rule
    $.each(this.rules, function(key) {
      if (MediaQuery.atLeast(key)) {
        matchedMq = key;
      }
    });

    // No match? No dice
    if (!matchedMq) return;

    // Plugin already initialized? We good
    if (this.currentPlugin instanceof this.rules[matchedMq].plugin) return;

    // Remove existing plugin-specific CSS classes
    $.each(MenuPlugins, function(key, value) {
      _this.$element.removeClass(value.cssClass);
    });

    // Add the CSS class for the new plugin
    this.$element.addClass(this.rules[matchedMq].cssClass);

    // Create an instance of the new plugin
    if (this.currentPlugin) {
      //don't know why but on nested elements data zfPlugin get's lost
      if (!this.currentPlugin.$element.data('zfPlugin') && this.storezfData) this.currentPlugin.$element.data('zfPlugin',this.storezfData);
      this.currentPlugin.destroy();
    }
    this._handleMarkup(this.rules[matchedMq].cssClass);
    this.currentPlugin = new this.rules[matchedMq].plugin(this.$element, {});
    this.storezfData = this.currentPlugin.$element.data('zfPlugin');

  }

  _handleMarkup(toSet){
    var _this = this, fromString = 'accordion';
    var $panels = $('[data-tabs-content='+this.$element.attr('id')+']');
    if ($panels.length) fromString = 'tabs';
    if (fromString === toSet) {
      return;
    };

    var tabsTitle = _this.allOptions.linkClass?_this.allOptions.linkClass:'tabs-title';
    var tabsPanel = _this.allOptions.panelClass?_this.allOptions.panelClass:'tabs-panel';

    this.$element.removeAttr('role');
    var $liHeads = this.$element.children('.'+tabsTitle+',[data-accordion-item]').removeClass(tabsTitle).removeClass('accordion-item').removeAttr('data-accordion-item');
    var $liHeadsA = $liHeads.children('a').removeClass('accordion-title');

    if (fromString === 'tabs') {
      $panels = $panels.children('.'+tabsPanel).removeClass(tabsPanel).removeAttr('role').removeAttr('aria-hidden').removeAttr('aria-labelledby');
      $panels.children('a').removeAttr('role').removeAttr('aria-controls').removeAttr('aria-selected');
    }else{
      $panels = $liHeads.children('[data-tab-content]').removeClass('accordion-content');
    };

    $panels.css({display:'',visibility:''});
    $liHeads.css({display:'',visibility:''});
    if (toSet === 'accordion') {
      $panels.each(function(key,value){
        $(value).appendTo($liHeads.get(key)).addClass('accordion-content').attr('data-tab-content','').removeClass('is-active').css({height:''});
        $('[data-tabs-content='+_this.$element.attr('id')+']').after('<div id="tabs-placeholder-'+_this.$element.attr('id')+'"></div>').detach();
        $liHeads.addClass('accordion-item').attr('data-accordion-item','');
        $liHeadsA.addClass('accordion-title');
      });
    }else if (toSet === 'tabs'){
      var $tabsContent = $('[data-tabs-content='+_this.$element.attr('id')+']');
      var $placeholder = $('#tabs-placeholder-'+_this.$element.attr('id'));
      if ($placeholder.length) {
        $tabsContent = $('<div class="tabs-content"></div>').insertAfter($placeholder).attr('data-tabs-content',_this.$element.attr('id'));
        $placeholder.remove();
      }else{
        $tabsContent = $('<div class="tabs-content"></div>').insertAfter(_this.$element).attr('data-tabs-content',_this.$element.attr('id'));
      };
      $panels.each(function(key,value){
        var tempValue = $(value).appendTo($tabsContent).addClass(tabsPanel);
        var hash = $liHeadsA.get(key).hash.slice(1);
        var id = $(value).attr('id') || GetYoDigits(6, 'accordion');
        if (hash !== id) {
          if (hash !== '') {
            $(value).attr('id',hash);
          }else{
            hash = id;
            $(value).attr('id',hash);
            $($liHeadsA.get(key)).attr('href',$($liHeadsA.get(key)).attr('href').replace('#','')+'#'+hash);
          };
        };
        var isActive = $($liHeads.get(key)).hasClass('is-active');
        if (isActive) {
          tempValue.addClass('is-active');
        };
      });
      $liHeads.addClass(tabsTitle);
    };
  }

  /**
   * Destroys the instance of the current plugin on this element, as well as the window resize handler that switches the plugins out.
   * @function
   */
  _destroy() {
    if (this.currentPlugin) this.currentPlugin.destroy();
    $(window).off('changed.zf.mediaquery', this._changedZfMediaQueryHandler);
  }
}

ResponsiveAccordionTabs.defaults = {};

export {ResponsiveAccordionTabs};
