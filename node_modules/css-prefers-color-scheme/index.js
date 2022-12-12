'use strict';

const colorIndexRegExp = /((?:not )?all and )?(\(color-index: *(22|48|70)\))/i;
const prefersColorSchemeRegExp = /prefers-color-scheme:/i;

const prefersColorSchemeInit = initialColorScheme => {
  const mediaQueryString = '(prefers-color-scheme: dark)';
  const mediaQueryList = window.matchMedia && matchMedia(mediaQueryString);
  const hasNativeSupport = mediaQueryList && mediaQueryList.media === mediaQueryString;

  const mediaQueryListener = () => {
    set(mediaQueryList.matches ? 'dark' : 'light');
  };

  const removeListener = () => {
    if (mediaQueryList) {
      mediaQueryList.removeListener(mediaQueryListener);
    }
  };

  const set = colorScheme => {
    if (colorScheme !== currentColorScheme) {
      currentColorScheme = colorScheme;

      if (typeof result.onChange === 'function') {
        result.onChange();
      }
    }

    [].forEach.call(document.styleSheets || [], styleSheet => {
      [].forEach.call(styleSheet.cssRules || [], cssRule => {
        const colorSchemeMatch = prefersColorSchemeRegExp.test(Object(cssRule.media).mediaText);

        if (colorSchemeMatch) {
          const index = [].indexOf.call(cssRule.parentStyleSheet.cssRules, cssRule);
          cssRule.parentStyleSheet.deleteRule(index);
        } else {
          const colorIndexMatch = (Object(cssRule.media).mediaText || '').match(colorIndexRegExp);

          if (colorIndexMatch) {
            cssRule.media.mediaText = ((/^dark$/i.test(colorScheme) ? colorIndexMatch[3] === '48' : /^light$/i.test(colorScheme) ? colorIndexMatch[3] === '70' : colorIndexMatch[3] === '22') ? 'not all and ' : '') + cssRule.media.mediaText.replace(colorIndexRegExp, '$2');
          }
        }
      });
    });
  };

  const result = Object.defineProperty({
    hasNativeSupport,
    removeListener
  }, 'scheme', {
    get: () => currentColorScheme,
    set
  }); // initialize the color scheme using the provided value, the system value, or light

  let currentColorScheme = initialColorScheme || (mediaQueryList && mediaQueryList.matches ? 'dark' : 'light');
  set(currentColorScheme); // listen for system changes

  if (mediaQueryList) {
    mediaQueryList.addListener(mediaQueryListener);
  }

  return result;
};

module.exports = prefersColorSchemeInit;
//# sourceMappingURL=index.js.map
