import marked from 'marked';
import DOMPurify from 'dompurify';

const TWITTER_USERNAME_REGEX = /(^|[^@\w])@(\w{1,15})\b/g;
const TWITTER_USERNAME_REPLACEMENT =
  '$1<a href="http://twitter.com/$2" target="_blank" rel="noreferrer nofollow noopener">@$2</a>';

const TWITTER_HASH_REGEX = /(^|\s)#(\w+)/g;
const TWITTER_HASH_REPLACEMENT =
  '$1<a href="https://twitter.com/hashtag/$2" target="_blank" rel="noreferrer nofollow noopener">#$2</a>';

class MessageFormatter {
  constructor(message, isATweet = false) {
    this.message = DOMPurify.sanitize(message);
    this.isATweet = isATweet;
    this.marked = marked;

    const renderer = {
      heading(text) {
        return `<strong>${text}</strong>`;
      },
      link(url, title, text) {
        return `<a rel="noreferrer noopener nofollow" href="${url}" class="link" title="${title}" target="_blank">${text}</a>`;
      },
    };
    this.marked.use({ renderer });
  }

  formatMessage() {
    const markedDownOutput = marked(this.message);
    if (this.isATweet) {
      const withParsedUserName = markedDownOutput.replace(
        TWITTER_USERNAME_REGEX,
        TWITTER_USERNAME_REPLACEMENT
      );
      const withParsedHash = withParsedUserName.replace(
        TWITTER_HASH_REGEX,
        TWITTER_HASH_REPLACEMENT
      );
      return withParsedHash;
    }
    return markedDownOutput;
  }

  get formattedMessage() {
    return this.formatMessage();
  }
}

export default MessageFormatter;
