import { defineIntegration } from '@sentry/core';
import { WINDOW } from '../helpers.js';

/**
 * Collects information about HTTP request headers and
 * attaches them to the event.
 */
const httpContextIntegration = defineIntegration(() => {
  return {
    name: 'HttpContext',
    preprocessEvent(event) {
      // if none of the information we want exists, don't bother
      if (!WINDOW.navigator && !WINDOW.location && !WINDOW.document) {
        return;
      }

      // grab as much info as exists and add it to the event
      const url = (event.request && event.request.url) || (WINDOW.location && WINDOW.location.href);
      const { referrer } = WINDOW.document || {};
      const { userAgent } = WINDOW.navigator || {};

      const headers = {
        ...(event.request && event.request.headers),
        ...(referrer && { Referer: referrer }),
        ...(userAgent && { 'User-Agent': userAgent }),
      };
      const request = { ...event.request, ...(url && { url }), headers };

      event.request = request;
    },
  };
});

export { httpContextIntegration };
//# sourceMappingURL=httpcontext.js.map
