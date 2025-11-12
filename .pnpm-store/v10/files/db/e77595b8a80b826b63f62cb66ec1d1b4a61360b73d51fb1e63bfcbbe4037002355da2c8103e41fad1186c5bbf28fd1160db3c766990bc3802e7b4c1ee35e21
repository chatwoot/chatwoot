Object.defineProperty(exports, '__esModule', { value: true });

const utils = require('@sentry/utils');
const currentScopes = require('./currentScopes.js');
const exports$1 = require('./exports.js');
const semanticAttributes = require('./semanticAttributes.js');
require('./tracing/errors.js');
require('./debug-build.js');
const trace = require('./tracing/trace.js');

const trpcCaptureContext = { mechanism: { handled: false, data: { function: 'trpcMiddleware' } } };

/**
 * Sentry tRPC middleware that captures errors and creates spans for tRPC procedures.
 */
function trpcMiddleware(options = {}) {
  return function (opts) {
    const { path, type, next, rawInput } = opts;
    const client = currentScopes.getClient();
    const clientOptions = client && client.getOptions();

    const trpcContext = {
      procedure_type: type,
    };

    if (options.attachRpcInput !== undefined ? options.attachRpcInput : clientOptions && clientOptions.sendDefaultPii) {
      trpcContext.input = utils.normalize(rawInput);
    }

    exports$1.setContext('trpc', trpcContext);

    function captureIfError(nextResult) {
      // TODO: Set span status based on what TRPCError was encountered
      if (
        typeof nextResult === 'object' &&
        nextResult !== null &&
        'ok' in nextResult &&
        !nextResult.ok &&
        'error' in nextResult
      ) {
        exports$1.captureException(nextResult.error, trpcCaptureContext);
      }
    }

    return trace.startSpanManual(
      {
        name: `trpc/${path}`,
        op: 'rpc.server',
        attributes: {
          [semanticAttributes.SEMANTIC_ATTRIBUTE_SENTRY_SOURCE]: 'route',
          [semanticAttributes.SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN]: 'auto.rpc.trpc',
        },
      },
      span => {
        let maybePromiseResult;
        try {
          maybePromiseResult = next();
        } catch (e) {
          exports$1.captureException(e, trpcCaptureContext);
          span.end();
          throw e;
        }

        if (utils.isThenable(maybePromiseResult)) {
          return maybePromiseResult.then(
            nextResult => {
              captureIfError(nextResult);
              span.end();
              return nextResult;
            },
            e => {
              exports$1.captureException(e, trpcCaptureContext);
              span.end();
              throw e;
            },
          ) ;
        } else {
          captureIfError(maybePromiseResult);
          span.end();
          return maybePromiseResult;
        }
      },
    );
  };
}

exports.trpcMiddleware = trpcMiddleware;
//# sourceMappingURL=trpc.js.map
