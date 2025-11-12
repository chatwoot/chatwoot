import { GLOBAL_OBJ } from '../worldwide.js';

// Based on https://github.com/angular/angular.js/pull/13945/files
// The MIT License


const WINDOW = GLOBAL_OBJ ;

/**
 * Tells whether current environment supports History API
 * {@link supportsHistory}.
 *
 * @returns Answer to the given question.
 */
function supportsHistory() {
  // NOTE: in Chrome App environment, touching history.pushState, *even inside
  //       a try/catch block*, will cause Chrome to output an error to console.error
  // borrowed from: https://github.com/angular/angular.js/pull/13945/files
  /* eslint-disable @typescript-eslint/no-unsafe-member-access */
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const chromeVar = (WINDOW ).chrome;
  const isChromePackagedApp = chromeVar && chromeVar.app && chromeVar.app.runtime;
  /* eslint-enable @typescript-eslint/no-unsafe-member-access */
  const hasHistoryApi = 'history' in WINDOW && !!WINDOW.history.pushState && !!WINDOW.history.replaceState;

  return !isChromePackagedApp && hasHistoryApi;
}

export { supportsHistory };
//# sourceMappingURL=supportsHistory.js.map
