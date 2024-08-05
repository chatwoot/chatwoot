import MessageFormatter from '../helpers/MessageFormatter';

/**
 * Composable for handling message formatting operations.
 * @returns {Object} An object containing methods for formatting and manipulating messages.
 */
export function useMessageFormatter() {
  const formatMessage = (message, isATweet, isAPrivateNote) => {
    const messageFormatter = new MessageFormatter(
      message,
      isATweet,
      isAPrivateNote
    );
    return messageFormatter.formattedMessage;
  };

  const getPlainText = (message, isATweet) => {
    const messageFormatter = new MessageFormatter(message, isATweet);
    return messageFormatter.plainText;
  };

  const truncateMessage = (description = '') => {
    if (description.length < 100) {
      return description;
    }
    return `${description.slice(0, 97)}...`;
  };

  const highlightContent = (
    content = '',
    searchTerm = '',
    highlightClass = ''
  ) => {
    const plainTextContent = getPlainText(content);
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
}
