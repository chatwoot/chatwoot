import { INBOX_TYPES } from 'dashboard/helper/inbox';
import {
  CAPABILITIES,
  hasCapability,
  isSessionProvider,
} from 'dashboard/helper/whatsappSession';

// Mirrors ContactInbox::WHATSAPP_MISSING_RECHECK_AFTER on the server, which is the one
// that decides: asking earlier only costs a request that changes nothing.
export const WHATSAPP_MISSING_RECHECK_AFTER_MS = 6 * 60 * 60 * 1000;

// When the conversation's number was last found to have no WhatsApp account (unix
// seconds), or null when there is nothing to warn about. The server decides what clears it
// (a reply, a live receipt, a lookup that finds the number) and pushes the change, so the
// thread is not read here: an echo is born delivered, and an import carries old receipts.
export const whatsappMissingCheckedAt = conversation =>
  conversation?.whatsapp_missing_checked_at || null;

export const isWhatsappMissingRecheckDue = (checkedAt, now = Date.now()) =>
  !!checkedAt && now - checkedAt * 1000 >= WHATSAPP_MISSING_RECHECK_AFTER_MS;

// Whether the compose form can ask this inbox about a number right now. A session that is
// not open has nobody to answer, and an unanswered check must not read as "no WhatsApp".
// Takes the compose form's inbox, whose keys are camelCased.
export const canCheckWhatsappNumber = inbox =>
  inbox?.channelType === INBOX_TYPES.WHATSAPP &&
  isSessionProvider(inbox.provider) &&
  hasCapability(inbox, CAPABILITIES.CHECK_NUMBER) &&
  inbox.providerConnection?.connection === 'open';
