import MessageFormatter from '../helpers/MessageFormatter';
import DOMPurify from 'dompurify';

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
    stripStyleCharacters(message) {
      return DOMPurify.sanitize(message, {
        FORBID_TAGS: ['style'],
        FORBID_ATTR: [
          'id',
          'class',
          'style',
          'bgcolor',
          'valign',
          'width',
          'face',
          'color',
          'height',
          'lang',
          'align',
          'size',
          'border',
        ],
      });
    },
  },
};
