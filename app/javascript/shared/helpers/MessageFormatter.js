import MarkdownIt from 'markdown-it';
import mila from 'markdown-it-link-attributes';
import mentionPlugin from './markdownIt/link';

const setImageSizing = inlineToken => {
  const imgSrc = inlineToken.attrGet('src');
  if (!imgSrc) return;
  const url = new URL(imgSrc);
  const width = url.searchParams.get('cw_image_width');
  if (width) {
    inlineToken.attrSet(
      'style',
      `width: ${width}; max-width: 100%; height: auto;`
    );
    return;
  }
  const height = url.searchParams.get('cw_image_height');
  if (height) inlineToken.attrSet('style', `height: ${height};`);
};

const processInlineToken = blockToken => {
  blockToken.children.forEach(inlineToken => {
    if (inlineToken.type === 'image') {
      setImageSizing(inlineToken);
    }
  });
};

const imgResizeManager = md => {
  // If the image URL carries a cw_image_width or cw_image_height query param,
  // add an inline style attribute so the rendered <img> respects the agent's
  // resize choice. Width takes precedence (HC drag-resize); height is kept for
  // legacy messages and the message-signature use case.
  md.core.ruler.after('inline', 'add-image-sizing', state => {
    state.tokens.forEach(blockToken => {
      if (blockToken.type === 'inline') {
        processInlineToken(blockToken);
      }
    });
  });
};

const createMarkdownInstance = (linkify = true) => {
  return MarkdownIt({
    html: false,
    xhtmlOut: true,
    breaks: true,
    langPrefix: 'language-',
    linkify,
    typographer: true,
    quotes: '\u201c\u201d\u2018\u2019',
    maxNesting: 20,
  })
    .disable(['lheading'])
    .use(mentionPlugin)
    .use(imgResizeManager)
    .use(mila, {
      attrs: {
        class: 'link',
        rel: 'noreferrer noopener nofollow',
        target: '_blank',
      },
    });
};

// Help center article tables persist column widths as an internal
// `<!--cw-colwidths:...-->` comment before the table. It exists only for the
// editor's markdown round-trip and must never surface as text — markdown-it runs
// with `html: false`, which would otherwise escape it into a visible comment in
// rendered/plain output (e.g. dashboard search snippets). Strip it on the way in.
const COLWIDTHS_MARKER_REGEX = /<!--cw-colwidths:[\d,]+-->\r?\n?/g;

const TWITTER_USERNAME_REGEX = /(^|[^@\w])@(\w{1,15})\b/g;
const TWITTER_USERNAME_REPLACEMENT = '$1[@$2](http://twitter.com/$2)';
const TWITTER_HASH_REGEX = /(^|\s)#(\w+)/g;
const TWITTER_HASH_REPLACEMENT = '$1[#$2](https://twitter.com/hashtag/$2)';

class MessageFormatter {
  constructor(
    message,
    isATweet = false,
    isAPrivateNote = false,
    linkify = true
  ) {
    this.message = (message || '').replace(COLWIDTHS_MARKER_REGEX, '');
    this.isAPrivateNote = isAPrivateNote;
    this.isATweet = isATweet;
    this.linkify = linkify;
    this.md = createMarkdownInstance(linkify);
  }

  formatMessage() {
    let updatedMessage = this.message;
    if (this.isATweet && !this.isAPrivateNote) {
      updatedMessage = updatedMessage.replace(
        TWITTER_USERNAME_REGEX,
        TWITTER_USERNAME_REPLACEMENT
      );
      updatedMessage = updatedMessage.replace(
        TWITTER_HASH_REGEX,
        TWITTER_HASH_REPLACEMENT
      );
    }
    return this.md.render(updatedMessage);
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
