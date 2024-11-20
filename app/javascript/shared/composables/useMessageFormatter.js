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
  const formatMessage = (message, isATweet, isAPrivateNote) => {
    const messageFormatter = new MessageFormatter(
      message,
      isATweet,
      isAPrivateNote
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
    const plainTextContent = getPlainText(content);

    // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions#escaping
    const escapedSearchTerm = searchTerm.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

    return plainTextContent.replace(
      new RegExp(`(${escapedSearchTerm})`, 'ig'),
      `<span class="${highlightClass}">$1</span>`
    );
  };

  return {
    formatMessage,
    getPlainText,
    truncateMessage,
    highlightContent,
  };
};
