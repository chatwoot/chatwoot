import { observe } from '../observe.js';

let interactionCountEstimate = 0;
let minKnownInteractionId = Infinity;
let maxKnownInteractionId = 0;

const updateEstimate = (entries) => {
  (entries ).forEach(e => {
    if (e.interactionId) {
      minKnownInteractionId = Math.min(minKnownInteractionId, e.interactionId);
      maxKnownInteractionId = Math.max(maxKnownInteractionId, e.interactionId);

      interactionCountEstimate = maxKnownInteractionId ? (maxKnownInteractionId - minKnownInteractionId) / 7 + 1 : 0;
    }
  });
};

let po;

/**
 * Returns the `interactionCount` value using the native API (if available)
 * or the polyfill estimate in this module.
 */
const getInteractionCount = () => {
  return po ? interactionCountEstimate : performance.interactionCount || 0;
};

/**
 * Feature detects native support or initializes the polyfill if needed.
 */
const initInteractionCountPolyfill = () => {
  if ('interactionCount' in performance || po) return;

  po = observe('event', updateEstimate, {
    type: 'event',
    buffered: true,
    durationThreshold: 0,
  } );
};

export { getInteractionCount, initInteractionCountPolyfill };
//# sourceMappingURL=interactionCountPolyfill.js.map
