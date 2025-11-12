import { normalize, isThenable } from '@sentry/utils';
import { getClient } from './currentScopes.js';
import { setContext, captureException } from './exports.js';
import { SEMANTIC_ATTRIBUTE_SENTRY_SOURCE, SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN } from './semanticAttributes.js';
import './tracing/errors.js';
import './debug-build.js';
import { startSpanManual } from './tracing/trace.js';

const trpcCaptureContext = { mechanism: { handled: false, data: { function: 'trpcMiddleware' } } };

/**
 * Sentry tRPC middleware that captures errors and creates spans for tRPC procedures.
 */
function trpcMiddleware(options = {}) {
  return function (opts) {
    const { path, type, next, rawInput } = opts;
    const client = getClient();
    const clientOptions = client && client.getOptions();

    const trpcContext = {
      procedure_type: type,
    };

    if (options.attachRpcInput !== undefined ? options.attachRpcInput : clientOptions && clientOptions.sendDefaultPii) {
      trpcContext.input = normalize(rawInput);
    }

    setContext('trpc', trpcContext);

    function captureIfError(nextResult) {
      // TODO: Set span status based on what TRPCError was encountered
      if (
        typeof nextResult === 'object' &&
        nextResult !== null &&
        'ok' in nextResult &&
        !nextResult.ok &&
        'error' in nextResult
      ) {
        captureException(nextResult.error, trpcCaptureContext);
      }
    }

    return startSpanManual(
      {
        name: `trpc/${path}`,
        op: 'rpc.server',
        attributes: {
          [SEMANTIC_ATTRIBUTE_SENTRY_SOURCE]: 'route',
          [SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN]: 'auto.rpc.trpc',
        },
      },
      span => {
        let maybePromiseResult;
        try {
          maybePromiseResult = next();
        } catch (e) {
          captureException(e, trpcCaptureContext);
          span.end();
          throw e;
        }

        if (isThenable(maybePromiseResult)) {
          return maybePromiseResult.then(
            nextResult => {
              captureIfError(nextResult);
              span.end();
              return nextResult;
            },
            e => {
              captureException(e, trpcCaptureContext);
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

export { trpcMiddleware };
//# sourceMappingURL=trpc.js.map
