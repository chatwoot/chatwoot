import { defineIntegration, getActiveSpan, getRootSpan } from '@sentry/core';
import { logger } from '@sentry/utils';
import { DEBUG_BUILD } from '../debug-build.js';
import { startProfileForSpan } from './startProfileForSpan.js';
import { isAutomatedPageLoadSpan, shouldProfileSpan, getActiveProfilesCount, findProfiledTransactionsFromEnvelope, takeProfileFromGlobalCache, createProfilingEvent, addProfilesToEnvelope } from './utils.js';

const INTEGRATION_NAME = 'BrowserProfiling';

const _browserProfilingIntegration = (() => {
  return {
    name: INTEGRATION_NAME,
    setup(client) {
      const activeSpan = getActiveSpan();
      const rootSpan = activeSpan && getRootSpan(activeSpan);

      if (rootSpan && isAutomatedPageLoadSpan(rootSpan)) {
        if (shouldProfileSpan(rootSpan)) {
          startProfileForSpan(rootSpan);
        }
      }

      client.on('spanStart', (span) => {
        if (span === getRootSpan(span) && shouldProfileSpan(span)) {
          startProfileForSpan(span);
        }
      });

      client.on('beforeEnvelope', (envelope) => {
        // if not profiles are in queue, there is nothing to add to the envelope.
        if (!getActiveProfilesCount()) {
          return;
        }

        const profiledTransactionEvents = findProfiledTransactionsFromEnvelope(envelope);
        if (!profiledTransactionEvents.length) {
          return;
        }

        const profilesToAddToEnvelope = [];

        for (const profiledTransaction of profiledTransactionEvents) {
          const context = profiledTransaction && profiledTransaction.contexts;
          const profile_id = context && context['profile'] && context['profile']['profile_id'];
          const start_timestamp = context && context['profile'] && context['profile']['start_timestamp'];

          if (typeof profile_id !== 'string') {
            DEBUG_BUILD && logger.log('[Profiling] cannot find profile for a span without a profile context');
            continue;
          }

          if (!profile_id) {
            DEBUG_BUILD && logger.log('[Profiling] cannot find profile for a span without a profile context');
            continue;
          }

          // Remove the profile from the span context before sending, relay will take care of the rest.
          if (context && context['profile']) {
            delete context.profile;
          }

          const profile = takeProfileFromGlobalCache(profile_id);
          if (!profile) {
            DEBUG_BUILD && logger.log(`[Profiling] Could not retrieve profile for span: ${profile_id}`);
            continue;
          }

          const profileEvent = createProfilingEvent(
            profile_id,
            start_timestamp ,
            profile,
            profiledTransaction ,
          );
          if (profileEvent) {
            profilesToAddToEnvelope.push(profileEvent);
          }
        }

        addProfilesToEnvelope(envelope , profilesToAddToEnvelope);
      });
    },
  };
}) ;

const browserProfilingIntegration = defineIntegration(_browserProfilingIntegration);

export { browserProfilingIntegration };
//# sourceMappingURL=integration.js.map
