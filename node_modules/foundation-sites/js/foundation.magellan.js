'use strict';


import $ from 'jquery';
import { onLoad, GetYoDigits } from './foundation.core.utils';
import { Plugin } from './foundation.core.plugin';
import { SmoothScroll } from './foundation.smoothScroll';

/**
 * Magellan module.
 * @module foundation.magellan
 * @requires foundation.smoothScroll
 */

class Magellan extends Plugin {
  /**
   * Creates a new instance of Magellan.
   * @class
   * @name Magellan
   * @fires Magellan#init
   * @param {Object} element - jQuery object to add the trigger to.
   * @param {Object} options - Overrides to the default plugin settings.
   */
  _setup(element, options) {
    this.$element = element;
    this.options  = $.extend({}, Magellan.defaults, this.$element.data(), options);
    this.className = 'Magellan'; // ie9 back compat

    this._init();
    this.calcPoints();
  }

  /**
   * Initializes the Magellan plugin and calls functions to get equalizer functioning on load.
   * @private
   */
  _init() {
    var id = this.$element[0].id || GetYoDigits(6, 'magellan');
    var _this = this;
    this.$targets = $('[data-magellan-target]');
    this.$links = this.$element.find('a');
    this.$element.attr({
      'data-resize': id,
      'data-scroll': id,
      'id': id
    });
    this.$active = $();
    this.scrollPos = parseInt(window.pageYOffset, 10);

    this._events();
  }

  /**
   * Calculates an array of pixel values that are the demarcation lines between locations on the page.
   * Can be invoked if new elements are added or the size of a location changes.
   * @function
   */
  calcPoints() {
    var _this = this,
        body = document.body,
        html = document.documentElement;

    this.points = [];
    this.winHeight = Math.round(Math.max(window.innerHeight, html.clientHeight));
    this.docHeight = Math.round(Math.max(body.scrollHeight, body.offsetHeight, html.clientHeight, html.scrollHeight, html.offsetHeight));

    this.$targets.each(function(){
      var $tar = $(this),
          pt = Math.round($tar.offset().top - _this.options.threshold);
      $tar.targetPoint = pt;
      _this.points.push(pt);
    });
  }

  /**
   * Initializes events for Magellan.
   * @private
   */
  _events() {
    var _this = this,
        $body = $('html, body'),
        opts = {
          duration: _this.options.animationDuration,
          easing:   _this.options.animationEasing
        };

    $(window).one('load', function(){
      if(_this.options.deepLinking){
        if(location.hash){
          _this.scrollToLoc(location.hash);
        }
      }
      _this.calcPoints();
      _this._updateActive();
    });

    _this.onLoadListener = onLoad($(window), function () {
      _this.$element
        .on({
          'resizeme.zf.trigger': _this.reflow.bind(_this),
          'scrollme.zf.trigger': _this._updateActive.bind(_this)
        })
        .on('click.zf.magellan', 'a[href^="#"]', function (e) {
          e.preventDefault();
          var arrival   = this.getAttribute('href');
          _this.scrollToLoc(arrival);
        });
    });

    this._deepLinkScroll = function(e) {
      if(_this.options.deepLinking) {
        _this.scrollToLoc(window.location.hash);
      }
    };

    $(window).on('hashchange', this._deepLinkScroll);
  }

  /**
   * Function to scroll to a given location on the page.
   * @param {String} loc - a properly formatted jQuery id selector. Example: '#foo'
   * @function
   */
  scrollToLoc(loc) {
    this._inTransition = true;
    var _this = this;

    var options = {
      animationEasing: this.options.animationEasing,
      animationDuration: this.options.animationDuration,
      threshold: this.options.threshold,
      offset: this.options.offset
    };

    SmoothScroll.scrollToLoc(loc, options, function() {
      _this._inTransition = false;
    })
  }

  /**
   * Calls necessary functions to update Magellan upon DOM change
   * @function
   */
  reflow() {
    this.calcPoints();
    this._updateActive();
  }

  /**
   * Updates the visibility of an active location link, and updates the url hash for the page, if deepLinking enabled.
   * @private
   * @function
   * @fires Magellan#update
   */
  _updateActive(/*evt, elem, scrollPos*/) {
    if(this._inTransition) return;

    const newScrollPos = parseInt(window.pageYOffset, 10);
    const isScrollingUp = this.scrollPos > newScrollPos;
    this.scrollPos = newScrollPos;

    let activeIdx;
    // Before the first point: no link
    if(newScrollPos < this.points[0]){ /* do nothing */ }
    // At the bottom of the page: last link
    else if(newScrollPos + this.winHeight === this.docHeight){ activeIdx = this.points.length - 1; }
    // Otherwhise, use the last visible link
    else{
      const visibleLinks = this.points.filter((p, i) => {
        return (p - this.options.offset - (isScrollingUp ? this.options.threshold : 0)) <= newScrollPos;
      });
      activeIdx = visibleLinks.length ? visibleLinks.length - 1 : 0;
    }

    // Get the new active link
    const $oldActive = this.$active;
    let activeHash = '';
    if(typeof activeIdx !== 'undefined'){
      this.$active = this.$links.filter('[href="#' + this.$targets.eq(activeIdx).data('magellan-target') + '"]');
      if (this.$active.length) activeHash = this.$active[0].getAttribute('href');
    }else{
      this.$active = $();
    }
    const isNewActive = !(!this.$active.length && !$oldActive.length) && !this.$active.is($oldActive);
    const isNewHash = activeHash !== window.location.hash;

    // Update the active link element
    if(isNewActive) {
      $oldActive.removeClass(this.options.activeClass);
      this.$active.addClass(this.options.activeClass);
    }

    // Update the hash (it may have changed with the same active link)
    if(this.options.deepLinking && isNewHash){
      if(window.history.pushState){
        // Set or remove the hash (see: https://stackoverflow.com/a/5298684/4317384
        const url = activeHash ? activeHash : window.location.pathname + window.location.search;
        window.history.pushState(null, null, url);
      }else{
        window.location.hash = activeHash;
      }
    }

    if (isNewActive) {
      /**
       * Fires when magellan is finished updating to the new active element.
       * @event Magellan#update
       */
    	this.$element.trigger('update.zf.magellan', [this.$active]);
	  }
  }

  /**
   * Destroys an instance of Magellan and resets the url of the window.
   * @function
   */
  _destroy() {
    this.$element.off('.zf.trigger .zf.magellan')
        .find(`.${this.options.activeClass}`).removeClass(this.options.activeClass);

    if(this.options.deepLinking){
      var hash = this.$active[0].getAttribute('href');
      window.location.hash.replace(hash, '');
    }

    $(window).off('hashchange', this._deepLinkScroll)
    if (this.onLoadListener) $(window).off(this.onLoadListener);
  }
}

/**
 * Default settings for plugin
 */
Magellan.defaults = {
  /**
   * Amount of time, in ms, the animated scrolling should take between locations.
   * @option
   * @type {number}
   * @default 500
   */
  animationDuration: 500,
  /**
   * Animation style to use when scrolling between locations. Can be `'swing'` or `'linear'`.
   * @option
   * @type {string}
   * @default 'linear'
   * @see {@link https://api.jquery.com/animate|Jquery animate}
   */
  animationEasing: 'linear',
  /**
   * Number of pixels to use as a marker for location changes.
   * @option
   * @type {number}
   * @default 50
   */
  threshold: 50,
  /**
   * Class applied to the active locations link on the magellan container.
   * @option
   * @type {string}
   * @default 'is-active'
   */
  activeClass: 'is-active',
  /**
   * Allows the script to manipulate the url of the current page, and if supported, alter the history.
   * @option
   * @type {boolean}
   * @default false
   */
  deepLinking: false,
  /**
   * Number of pixels to offset the scroll of the page on item click if using a sticky nav bar.
   * @option
   * @type {number}
   * @default 0
   */
  offset: 0
}

export {Magellan};
