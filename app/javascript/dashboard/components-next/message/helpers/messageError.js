import { MESSAGE_STATUS } from '../constants';

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
