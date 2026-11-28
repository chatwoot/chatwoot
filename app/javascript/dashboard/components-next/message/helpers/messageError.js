import { MESSAGE_STATUS } from '../constants';
import { hasOneDayPassed } from 'shared/helpers/timeHelper';

/**
 * Returns the error to show under a message, or '' when there is none.
 *
 * `contentAttributes.externalError` is set by the server when delivery to the
 * channel failed. `meta` is set only in the browser when the send request itself
 * failed (e.g. no network); message payloads from the server never include it.
 *
 * @param {Object} message - camelCased message props
 * @param {string} fallback - shown when the request failed without an error text
 * @returns {string}
 */
export const getMessageError = (
  { status, contentAttributes, meta } = {},
  fallback = ''
) => {
  if (contentAttributes?.externalError) return contentAttributes.externalError;
  if (status === MESSAGE_STATUS.FAILED && meta) return meta.error || fallback;
  return '';
};

/**
 * Whether a failed message can be sent again.
 *
 * A reply that failed in the browser (`meta` is set) is retried from the stored
 * payload, which keeps its `files`, so it is retryable even when it has no text
 * and no attachment records yet (e.g. an attachment sent without a caption).
 *
 * @param {Object} message - camelCased message props
 * @returns {boolean}
 */
export const canRetryMessage = ({
  createdAt,
  content,
  attachments,
  meta,
} = {}) => {
  if (hasOneDayPassed(createdAt)) return false;
  const hasContent = content !== null;
  const hasAttachments = Array.isArray(attachments) && attachments.length > 0;
  return hasContent || hasAttachments || !!meta;
};
