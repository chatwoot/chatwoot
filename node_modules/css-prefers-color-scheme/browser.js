var initPrefersColorScheme = (function () {
	'use strict';

	var colorIndexRegExp = /((?:not )?all and )?(\(color-index: *(22|48|70)\))/i;
	var prefersColorSchemeRegExp = /prefers-color-scheme:/i;

	var prefersColorSchemeInit = function prefersColorSchemeInit(initialColorScheme) {
	  var mediaQueryString = '(prefers-color-scheme: dark)';
	  var mediaQueryList = window.matchMedia && matchMedia(mediaQueryString);
	  var hasNativeSupport = mediaQueryList && mediaQueryList.media === mediaQueryString;

	  var mediaQueryListener = function mediaQueryListener() {
	    set(mediaQueryList.matches ? 'dark' : 'light');
	  };

	  var removeListener = function removeListener() {
	    if (mediaQueryList) {
	      mediaQueryList.removeListener(mediaQueryListener);
	    }
	  };

	  var set = function set(colorScheme) {
	    if (colorScheme !== currentColorScheme) {
	      currentColorScheme = colorScheme;

	      if (typeof result.onChange === 'function') {
	        result.onChange();
	      }
	    }

	    [].forEach.call(document.styleSheets || [], function (styleSheet) {
	      [].forEach.call(styleSheet.cssRules || [], function (cssRule) {
	        var colorSchemeMatch = prefersColorSchemeRegExp.test(Object(cssRule.media).mediaText);

	        if (colorSchemeMatch) {
	          var index = [].indexOf.call(cssRule.parentStyleSheet.cssRules, cssRule);
	          cssRule.parentStyleSheet.deleteRule(index);
	        } else {
	          var colorIndexMatch = (Object(cssRule.media).mediaText || '').match(colorIndexRegExp);

	          if (colorIndexMatch) {
	            cssRule.media.mediaText = ((/^dark$/i.test(colorScheme) ? colorIndexMatch[3] === '48' : /^light$/i.test(colorScheme) ? colorIndexMatch[3] === '70' : colorIndexMatch[3] === '22') ? 'not all and ' : '') + cssRule.media.mediaText.replace(colorIndexRegExp, '$2');
	          }
	        }
	      });
	    });
	  };

	  var result = Object.defineProperty({
	    hasNativeSupport: hasNativeSupport,
	    removeListener: removeListener
	  }, 'scheme', {
	    get: function get() {
	      return currentColorScheme;
	    },
	    set: set
	  }); // initialize the color scheme using the provided value, the system value, or light

	  var currentColorScheme = initialColorScheme || (mediaQueryList && mediaQueryList.matches ? 'dark' : 'light');
	  set(currentColorScheme); // listen for system changes

	  if (mediaQueryList) {
	    mediaQueryList.addListener(mediaQueryListener);
	  }

	  return result;
	};

	return prefersColorSchemeInit;

}());
//# sourceMappingURL=browser.js.map
