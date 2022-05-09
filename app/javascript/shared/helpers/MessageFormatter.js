import { marked } from 'marked';
import DOMPurify from 'dompurify';
import { escapeHtml } from './HTMLSanitizer';

const TWITTER_USERNAME_REGEX = /(^|[^@\w])@(\w{1,15})\b/g;
const TWITTER_USERNAME_REPLACEMENT =
  '$1<a href="http://twitter.com/$2" target="_blank" rel="noreferrer nofollow noopener">@$2</a>';

const TWITTER_HASH_REGEX = /(^|\s)#(\w+)/g;
const TWITTER_HASH_REPLACEMENT =
  '$1<a href="https://twitter.com/hashtag/$2" target="_blank" rel="noreferrer nofollow noopener">#$2</a>';

const USER_MENTIONS_REGEX = /mention:\/\/(user|team)\/(\d+)\/(.+)/gm;

class MessageFormatter {
  constructor(message, isATweet = false, isAPrivateNote = false) {
    this.message = DOMPurify.sanitize(escapeHtml(message || ''));
    this.isAPrivateNote = isAPrivateNote;
    this.isATweet = isATweet;
    this.marked = marked;

    const renderer = {
      heading(text) {
        return `<strong>${text}</strong>`;
      },
      link(url, title, text) {
        const mentionRegex = new RegExp(USER_MENTIONS_REGEX);
        if (url.match(mentionRegex)) {
          return `<span class="prosemirror-mention-node">${text}</span>`;
        }
        return `<a rel="noreferrer noopener nofollow" href="${url}" class="link" title="${title ||
          ''}" target="_blank">${text}</a>`;
      },
    };
    this.marked.use({ renderer });
  }

  formatMessage() {
    if (this.isATweet && !this.isAPrivateNote) {
      const withUserName = this.message.replace(
        TWITTER_USERNAME_REGEX,
        TWITTER_USERNAME_REPLACEMENT
      );
      const withHash = withUserName.replace(
        TWITTER_HASH_REGEX,
        TWITTER_HASH_REPLACEMENT
      );
      const markedDownOutput = marked(withHash);
      return markedDownOutput;
    }
    DOMPurify.addHook('afterSanitizeAttributes', node => {
      if ('target' in node) node.setAttribute('target', '_blank');
    });
    return DOMPurify.sanitize(
      marked(this.message, { breaks: true, gfm: true })
    );
  }

  get formattedMessage() {
    return this.formatMessage();
  }

  get plainText() {
    const strippedOutHtml = new DOMParser().parseFromString(
      this.formattedMessage,
      'text/html'
    );
    return strippedOutHtml.body.textContent || '';
  }
}

export default MessageFormatter;
