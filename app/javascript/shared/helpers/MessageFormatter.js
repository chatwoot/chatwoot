import { escapeHtml } from './HTMLSanitizer';

class MessageFormatter {
  constructor(message) {
    this.message = escapeHtml(message || '') || '';
  }

  formatMessage() {
    const linkifiedMessage = this.linkify();
    return linkifiedMessage.replace(/\n/g, '<br>');
  }

  linkify() {
    if (!this.message) {
      return '';
    }
    const urlRegex = /(https?:\/\/[^\s]+)/g;
    return this.message.replace(
      urlRegex,
      url =>
        `<a rel="noreferrer noopener nofollow" href="${url}" class="link" target="_blank">${url}</a>`
    );
  }

  get formattedMessage() {
    return this.formatMessage();
  }
}

export default MessageFormatter;
