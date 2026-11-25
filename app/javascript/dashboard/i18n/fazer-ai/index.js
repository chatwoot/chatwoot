/**
 * fazer.ai fork translations.
 *
 * Every key under `fazer-ai/locale/<lang>/` belongs to this fork: strings for
 * our own features plus `overrides.json`, which replaces upstream strings.
 * The upstream tree in `../locale/` stays byte-identical to the Chatwoot
 * release we track, so upstream syncs never conflict with our translations.
 *
 * Files are picked up by directory scan, so adding a language means creating
 * one folder and adding a namespace means creating one file. Nothing else
 * changes, which also keeps CE -> Pro merges conflict-free.
 *
 * File naming: a namespace that is entirely ours gets its own file
 * (`kanban.json`, `internalChat.json`); keys we add inside an upstream
 * namespace live in a file named after the upstream file they extend
 * (`conversation.json` extends `../locale/<lang>/conversation.json`).
 */

import {
  buildForkMessages,
  mergeForkMessages,
} from 'shared/helpers/forkTranslations';

const modules = import.meta.glob('./locale/*/*.json', { eager: true });

export const forkMessages = buildForkMessages(
  modules,
  path => path.split('/')[2]
);

/**
 * Deep merges the fork translations on top of upstream's, per locale.
 * Locales without a fork folder are returned untouched.
 */
export const withForkMessages = upstreamMessages =>
  mergeForkMessages(upstreamMessages, forkMessages);

export default withForkMessages;
