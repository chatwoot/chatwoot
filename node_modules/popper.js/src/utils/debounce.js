import isBrowser from './isBrowser';

const timeoutDuration = (function(){
  const longerTimeoutBrowsers = ['Edge', 'Trident', 'Firefox'];
  for (let i = 0; i < longerTimeoutBrowsers.length; i += 1) {
    if (isBrowser && navigator.userAgent.indexOf(longerTimeoutBrowsers[i]) >= 0) {
      return 1;
    }
  }
  return 0;
}());

export function microtaskDebounce(fn) {
  let called = false
  return () => {
    if (called) {
      return
    }
    called = true
    window.Promise.resolve().then(() => {
      called = false
      fn()
    })
  }
}

export function taskDebounce(fn) {
  let scheduled = false;
  return () => {
    if (!scheduled) {
      scheduled = true;
      setTimeout(() => {
        scheduled = false;
        fn();
      }, timeoutDuration);
    }
  };
}

const supportsMicroTasks = isBrowser && window.Promise


/**
* Create a debounced version of a method, that's asynchronously deferred
* but called in the minimum time possible.
*
* @method
* @memberof Popper.Utils
* @argument {Function} fn
* @returns {Function}
*/
export default (supportsMicroTasks
  ? microtaskDebounce
  : taskDebounce);
