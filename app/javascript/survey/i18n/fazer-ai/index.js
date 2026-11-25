/**
 * fazer.ai fork translations for the survey app.
 *
 * Same contract as the dashboard overlay: every key under `fazer-ai/locale/<lang>.json`
 * belongs to this fork, and the upstream tree in `../locale/` stays byte-identical to the
 * Chatwoot release we track, so upstream syncs never conflict with our strings.
 *
 * The survey ships one file per language rather than a folder, because it is a single
 * small namespace.
 */

import {
  buildForkMessages,
  mergeForkMessages,
} from 'shared/helpers/forkTranslations';

const modules = import.meta.glob('./locale/*.json', { eager: true });

export const forkMessages = buildForkMessages(modules, path =>
  path.split('/').pop().replace('.json', '')
);

export const withForkMessages = upstreamMessages =>
  mergeForkMessages(upstreamMessages, forkMessages);

export default withForkMessages;
