import { escapeHtml } from './HTMLSanitizer';
const TWITTER_USERNAME_REGEX = /(^|[^@\w])@(\w{1,15})\b/g;
const TWITTER_USERNAME_REPLACEMENT =
  '$1<a href="http://twitter.com/$2" target="_blank" rel="noreferrer nofollow noopener">@$2</a>';

const TWITTER_HASH_REGEX = /(^|\s)#(\w+)/g;
const TWITTER_HASH_REPLACEMENT =
  '$1<a href="https://twitter.com/hashtag/$2" target="_blank" rel="noreferrer nofollow noopener">#$2</a>';

class MessageFormatter {
  constructor(message, isATweet = false) {
    this.message = escapeHtml(message || '') || '';
    this.isATweet = isATweet;
  }

  formatMessage() {
    const linkifiedMessage = this.linkify();
    const messageWithNextLines = linkifiedMessage.replace(/\n/g, '<br>');
    if (this.isATweet) {
      const messageWithUserName = messageWithNextLines.replace(
        TWITTER_USERNAME_REGEX,
        TWITTER_USERNAME_REPLACEMENT
      );
      return messageWithUserName.replace(
        TWITTER_HASH_REGEX,
        TWITTER_HASH_REPLACEMENT
      );
    }
    return messageWithNextLines;
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
