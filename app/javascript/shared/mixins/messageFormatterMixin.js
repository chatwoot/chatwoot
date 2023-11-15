import MessageFormatter from '../helpers/MessageFormatter';

export default {
  methods: {
    formatMessage(message, isATweet, isAPrivateNote) {
      const messageFormatter = new MessageFormatter(
        message,
        isATweet,
        isAPrivateNote
      );
      return messageFormatter.formattedMessage;
    },
    getPlainText(message, isATweet) {
      const messageFormatter = new MessageFormatter(message, isATweet);
      return messageFormatter.plainText;
    },
    truncateMessage(description = '') {
      if (description.length < 100) {
        return description;
      }

      return `${description.slice(0, 97)}...`;
    },

    highlightContent(content = '', searchTerm = '', highlightClass = '') {
      const plainTextContent = this.getPlainText(content);

      // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions#escaping
      const escapedSearchTerm = searchTerm.replace(
        /[.*+?^${}()|[\]\\]/g,
        '\\$&'
      );

      return plainTextContent.replace(
        new RegExp(`(${escapedSearchTerm})`, 'ig'),
        `<span class="${highlightClass}">$1</span>`
      );
    },
  },
};
