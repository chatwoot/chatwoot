import { isError } from '../is.js';
import { fill, addNonEnumerableProperty } from '../object.js';
import { supportsNativeFetch } from '../supports.js';
import { timestampInSeconds } from '../time.js';
import { GLOBAL_OBJ } from '../worldwide.js';
import { addHandler, maybeInstrument, triggerHandlers } from './handlers.js';

/**
 * Add an instrumentation handler for when a fetch request happens.
 * The handler function is called once when the request starts and once when it ends,
 * which can be identified by checking if it has an `endTimestamp`.
 *
 * Use at your own risk, this might break without changelog notice, only used internally.
 * @hidden
 */
function addFetchInstrumentationHandler(
  handler,
  skipNativeFetchCheck,
) {
  const type = 'fetch';
  addHandler(type, handler);
  maybeInstrument(type, () => instrumentFetch(undefined, skipNativeFetchCheck));
}

/**
 * Add an instrumentation handler for long-lived fetch requests, like consuming server-sent events (SSE) via fetch.
 * The handler will resolve the request body and emit the actual `endTimestamp`, so that the
 * span can be updated accordingly.
 *
 * Only used internally
 * @hidden
 */
function addFetchEndInstrumentationHandler(handler) {
  const type = 'fetch-body-resolved';
  addHandler(type, handler);
  maybeInstrument(type, () => instrumentFetch(streamHandler));
}

function instrumentFetch(onFetchResolved, skipNativeFetchCheck = false) {
  if (skipNativeFetchCheck && !supportsNativeFetch()) {
    return;
  }

  fill(GLOBAL_OBJ, 'fetch', function (originalFetch) {
    return function (...args) {
      const { method, url } = parseFetchArgs(args);
      const handlerData = {
        args,
        fetchData: {
          method,
          url,
        },
        startTimestamp: timestampInSeconds() * 1000,
      };

      // if there is no callback, fetch is instrumented directly
      if (!onFetchResolved) {
        triggerHandlers('fetch', {
          ...handlerData,
        });
      }

      // We capture the stack right here and not in the Promise error callback because Safari (and probably other
      // browsers too) will wipe the stack trace up to this point, only leaving us with this file which is useless.

      // NOTE: If you are a Sentry user, and you are seeing this stack frame,
      //       it means the error, that was caused by your fetch call did not
      //       have a stack trace, so the SDK backfilled the stack trace so
      //       you can see which fetch call failed.
      const virtualStackTrace = new Error().stack;

      // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
      return originalFetch.apply(GLOBAL_OBJ, args).then(
        async (response) => {
          if (onFetchResolved) {
            onFetchResolved(response);
          } else {
            triggerHandlers('fetch', {
              ...handlerData,
              endTimestamp: timestampInSeconds() * 1000,
              response,
            });
          }

          return response;
        },
        (error) => {
          triggerHandlers('fetch', {
            ...handlerData,
            endTimestamp: timestampInSeconds() * 1000,
            error,
          });

          if (isError(error) && error.stack === undefined) {
            // NOTE: If you are a Sentry user, and you are seeing this stack frame,
            //       it means the error, that was caused by your fetch call did not
            //       have a stack trace, so the SDK backfilled the stack trace so
            //       you can see which fetch call failed.
            error.stack = virtualStackTrace;
            addNonEnumerableProperty(error, 'framesToPop', 1);
          }

          // NOTE: If you are a Sentry user, and you are seeing this stack frame,
          //       it means the sentry.javascript SDK caught an error invoking your application code.
          //       This is expected behavior and NOT indicative of a bug with sentry.javascript.
          throw error;
        },
      );
    };
  });
}

async function resolveResponse(res, onFinishedResolving) {
  if (res && res.body && res.body.getReader) {
    const responseReader = res.body.getReader();

    // eslint-disable-next-line no-inner-declarations
    async function consumeChunks({ done }) {
      if (!done) {
        try {
          // abort reading if read op takes more than 5s
          const result = await Promise.race([
            responseReader.read(),
            new Promise(res => {
              setTimeout(() => {
                res({ done: true });
              }, 5000);
            }),
          ]);
          await consumeChunks(result);
        } catch (error) {
          // handle error if needed
        }
      } else {
        return Promise.resolve();
      }
    }

    return responseReader
      .read()
      .then(consumeChunks)
      .then(onFinishedResolving)
      .catch(() => undefined);
  }
}

async function streamHandler(response) {
  // clone response for awaiting stream
  let clonedResponseForResolving;
  try {
    clonedResponseForResolving = response.clone();
  } catch (e) {
    return;
  }

  await resolveResponse(clonedResponseForResolving, () => {
    triggerHandlers('fetch-body-resolved', {
      endTimestamp: timestampInSeconds() * 1000,
      response,
    });
  });
}

function hasProp(obj, prop) {
  return !!obj && typeof obj === 'object' && !!(obj )[prop];
}

function getUrlFromResource(resource) {
  if (typeof resource === 'string') {
    return resource;
  }

  if (!resource) {
    return '';
  }

  if (hasProp(resource, 'url')) {
    return resource.url;
  }

  if (resource.toString) {
    return resource.toString();
  }

  return '';
}

/**
 * Parses the fetch arguments to find the used Http method and the url of the request.
 * Exported for tests only.
 */
function parseFetchArgs(fetchArgs) {
  if (fetchArgs.length === 0) {
    return { method: 'GET', url: '' };
  }

  if (fetchArgs.length === 2) {
    const [url, options] = fetchArgs ;

    return {
      url: getUrlFromResource(url),
      method: hasProp(options, 'method') ? String(options.method).toUpperCase() : 'GET',
    };
  }

  const arg = fetchArgs[0];
  return {
    url: getUrlFromResource(arg ),
    method: hasProp(arg, 'method') ? String(arg.method).toUpperCase() : 'GET',
  };
}

export { addFetchEndInstrumentationHandler, addFetchInstrumentationHandler, parseFetchArgs };
//# sourceMappingURL=fetch.js.map
