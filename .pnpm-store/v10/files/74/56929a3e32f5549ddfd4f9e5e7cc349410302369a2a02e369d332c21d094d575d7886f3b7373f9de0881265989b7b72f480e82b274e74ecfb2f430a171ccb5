import { makePromiseBuffer, forEachEnvelopeItem, envelopeItemTypeToDataCategory, isRateLimited, resolvedSyncPromise, createEnvelope, SentryError, logger, serializeEnvelope, updateRateLimits } from '@sentry/utils';
import { DEBUG_BUILD } from '../debug-build.js';

const DEFAULT_TRANSPORT_BUFFER_SIZE = 64;

/**
 * Creates an instance of a Sentry `Transport`
 *
 * @param options
 * @param makeRequest
 */
function createTransport(
  options,
  makeRequest,
  buffer = makePromiseBuffer(
    options.bufferSize || DEFAULT_TRANSPORT_BUFFER_SIZE,
  ),
) {
  let rateLimits = {};
  const flush = (timeout) => buffer.drain(timeout);

  function send(envelope) {
    const filteredEnvelopeItems = [];

    // Drop rate limited items from envelope
    forEachEnvelopeItem(envelope, (item, type) => {
      const dataCategory = envelopeItemTypeToDataCategory(type);
      if (isRateLimited(rateLimits, dataCategory)) {
        const event = getEventForEnvelopeItem(item, type);
        options.recordDroppedEvent('ratelimit_backoff', dataCategory, event);
      } else {
        filteredEnvelopeItems.push(item);
      }
    });

    // Skip sending if envelope is empty after filtering out rate limited events
    if (filteredEnvelopeItems.length === 0) {
      return resolvedSyncPromise({});
    }

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const filteredEnvelope = createEnvelope(envelope[0], filteredEnvelopeItems );

    // Creates client report for each item in an envelope
    const recordEnvelopeLoss = (reason) => {
      forEachEnvelopeItem(filteredEnvelope, (item, type) => {
        const event = getEventForEnvelopeItem(item, type);
        options.recordDroppedEvent(reason, envelopeItemTypeToDataCategory(type), event);
      });
    };

    const requestTask = () =>
      makeRequest({ body: serializeEnvelope(filteredEnvelope) }).then(
        response => {
          // We don't want to throw on NOK responses, but we want to at least log them
          if (response.statusCode !== undefined && (response.statusCode < 200 || response.statusCode >= 300)) {
            DEBUG_BUILD && logger.warn(`Sentry responded with status code ${response.statusCode} to sent event.`);
          }

          rateLimits = updateRateLimits(rateLimits, response);
          return response;
        },
        error => {
          recordEnvelopeLoss('network_error');
          throw error;
        },
      );

    return buffer.add(requestTask).then(
      result => result,
      error => {
        if (error instanceof SentryError) {
          DEBUG_BUILD && logger.error('Skipped sending event because buffer is full.');
          recordEnvelopeLoss('queue_overflow');
          return resolvedSyncPromise({});
        } else {
          throw error;
        }
      },
    );
  }

  return {
    send,
    flush,
  };
}

function getEventForEnvelopeItem(item, type) {
  if (type !== 'event' && type !== 'transaction') {
    return undefined;
  }

  return Array.isArray(item) ? (item )[1] : undefined;
}

export { DEFAULT_TRANSPORT_BUFFER_SIZE, createTransport };
//# sourceMappingURL=base.js.map
