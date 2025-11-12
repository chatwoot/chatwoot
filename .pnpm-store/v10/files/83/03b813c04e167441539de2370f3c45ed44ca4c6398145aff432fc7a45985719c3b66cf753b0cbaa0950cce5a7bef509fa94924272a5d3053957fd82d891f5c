Object.defineProperty(exports, '__esModule', { value: true });

const core = require('@sentry/core');
const utils = require('@sentry/utils');

const WINDOW = utils.GLOBAL_OBJ ;

let ignoreOnError = 0;

/**
 * @hidden
 */
function shouldIgnoreOnError() {
  return ignoreOnError > 0;
}

/**
 * @hidden
 */
function ignoreNextOnError() {
  // onerror should trigger before setTimeout
  ignoreOnError++;
  setTimeout(() => {
    ignoreOnError--;
  });
}

/**
 * Instruments the given function and sends an event to Sentry every time the
 * function throws an exception.
 *
 * @param fn A function to wrap. It is generally safe to pass an unbound function, because the returned wrapper always
 * has a correct `this` context.
 * @returns The wrapped function.
 * @hidden
 */
function wrap(
  fn,
  options

 = {},
  before,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
) {
  // for future readers what this does is wrap a function and then create
  // a bi-directional wrapping between them.
  //
  // example: wrapped = wrap(original);
  //  original.__sentry_wrapped__ -> wrapped
  //  wrapped.__sentry_original__ -> original

  if (typeof fn !== 'function') {
    return fn;
  }

  try {
    // if we're dealing with a function that was previously wrapped, return
    // the original wrapper.
    const wrapper = fn.__sentry_wrapped__;
    if (wrapper) {
      return wrapper;
    }

    // We don't wanna wrap it twice
    if (utils.getOriginalFunction(fn)) {
      return fn;
    }
  } catch (e) {
    // Just accessing custom props in some Selenium environments
    // can cause a "Permission denied" exception (see raven-js#495).
    // Bail on wrapping and return the function as-is (defers to window.onerror).
    return fn;
  }

  /* eslint-disable prefer-rest-params */
  // It is important that `sentryWrapped` is not an arrow function to preserve the context of `this`
  const sentryWrapped = function () {
    const args = Array.prototype.slice.call(arguments);

    try {
      if (before && typeof before === 'function') {
        before.apply(this, arguments);
      }

      // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-member-access
      const wrappedArguments = args.map((arg) => wrap(arg, options));

      // Attempt to invoke user-land function
      // NOTE: If you are a Sentry user, and you are seeing this stack frame, it
      //       means the sentry.javascript SDK caught an error invoking your application code. This
      //       is expected behavior and NOT indicative of a bug with sentry.javascript.
      return fn.apply(this, wrappedArguments);
    } catch (ex) {
      ignoreNextOnError();

      core.withScope(scope => {
        scope.addEventProcessor(event => {
          if (options.mechanism) {
            utils.addExceptionTypeValue(event, undefined, undefined);
            utils.addExceptionMechanism(event, options.mechanism);
          }

          event.extra = {
            ...event.extra,
            arguments: args,
          };

          return event;
        });

        core.captureException(ex);
      });

      throw ex;
    }
  };
  /* eslint-enable prefer-rest-params */

  // Accessing some objects may throw
  // ref: https://github.com/getsentry/sentry-javascript/issues/1168
  try {
    for (const property in fn) {
      if (Object.prototype.hasOwnProperty.call(fn, property)) {
        sentryWrapped[property] = fn[property];
      }
    }
  } catch (_oO) {} // eslint-disable-line no-empty

  // Signal that this function has been wrapped/filled already
  // for both debugging and to prevent it to being wrapped/filled twice
  utils.markFunctionWrapped(sentryWrapped, fn);

  utils.addNonEnumerableProperty(fn, '__sentry_wrapped__', sentryWrapped);

  // Restore original function name (not all browsers allow that)
  try {
    const descriptor = Object.getOwnPropertyDescriptor(sentryWrapped, 'name') ;
    if (descriptor.configurable) {
      Object.defineProperty(sentryWrapped, 'name', {
        get() {
          return fn.name;
        },
      });
    }
    // eslint-disable-next-line no-empty
  } catch (_oO) {}

  return sentryWrapped;
}

exports.WINDOW = WINDOW;
exports.ignoreNextOnError = ignoreNextOnError;
exports.shouldIgnoreOnError = shouldIgnoreOnError;
exports.wrap = wrap;
//# sourceMappingURL=helpers.js.map
