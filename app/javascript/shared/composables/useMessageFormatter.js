import MessageFormatter from '../helpers/MessageFormatter';

/**
 * A composable providing utility functions for message formatting.
 *
 * @returns {Object} A set of functions for message formatting.
 */
export const useMessageFormatter = () => {
  /**
   * Formats a message based on specified conditions.
   *
   * @param {string} message - The message to be formatted.
   * @param {boolean} isATweet - Whether the message is a tweet.
   * @param {boolean} isAPrivateNote - Whether the message is a private note.
   * @returns {string} - The formatted message.
   */
  // TODO: ref:https://github.com/chatwoot/chatwoot/pull/10725#discussion_r1925300874
  const formatMessage = (message, isATweet, isAPrivateNote, linkify) => {
    const messageFormatter = new MessageFormatter(
      message,
      isATweet,
      isAPrivateNote,
      linkify
    );
    return messageFormatter.formattedMessage;
  };

  /**
   * Converts a message to plain text.
   *
   * @param {string} message - The message to be converted.
   * @param {boolean} isATweet - Whether the message is a tweet.
   * @returns {string} - The plain text message.
   */
  const getPlainText = (message, isATweet) => {
    const messageFormatter = new MessageFormatter(message, isATweet);
    return messageFormatter.plainText;
  };

  /**
   * Truncates a description to a maximum length of 100 characters.
   *
   * @param {string} [description=''] - The description to be truncated.
   * @returns {string} - The truncated description.
   */
  const truncateMessage = (description = '') => {
    if (description.length < 100) {
      return description;
    }

    return `${description.slice(0, 97)}...`;
  };

  /**
   * Lowercases text and strips accents. NFC input keeps its length, so indexes carry over.
   *
   * @param {string} text - The text to normalize.
   * @returns {string} - The normalized text.
   */
  const normalizeForSearch = text =>
    text
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .normalize('NFC')
      .toLowerCase();

  /**
   * Highlights occurrences of a search term within given content.
   *
   * @param {string} [content=''] - The content in which to search.
   * @param {string} [searchTerm=''] - The term to search for.
   * @param {string} [highlightClass=''] - The CSS class to apply to the highlighted term.
   * @returns {string} - The content with highlighted terms.
   */
  const highlightContent = (
    content = '',
    searchTerm = '',
    highlightClass = ''
  ) => {
    const plainTextContent = getPlainText(content).normalize('NFC');
    const term = normalizeForSearch(searchTerm);
    const normalizedContent = normalizeForSearch(plainTextContent);
    // Accents NFC can't combine (like "g\u0303") shorten the text, so its indexes would be off
    if (!term || normalizedContent.length !== plainTextContent.length) {
      return plainTextContent;
    }

    // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions#escaping
    const escapedTerm = term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const matches = normalizedContent.matchAll(new RegExp(escapedTerm, 'g'));

    return [...matches].reduceRight((text, { index }) => {
      const end = index + term.length;
      return `${text.slice(0, index)}<span class="${highlightClass}">${text.slice(index, end)}</span>${text.slice(end)}`;
    }, plainTextContent);
  };

  return {
    formatMessage,
    getPlainText,
    truncateMessage,
    normalizeForSearch,
    highlightContent,
  };
};
