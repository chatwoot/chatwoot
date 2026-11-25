import MarkdownIt from 'markdown-it';

// `html: true` so an HTML block counts as a block, as it does for the
// CommonMark renderers on the server.
const md = new MarkdownIt({ html: true });

// A markdown hard break written as two trailing spaces. Unlike `\` + newline,
// an authored trailing backslash (`C:\`) cannot escape it, and the channels
// that send the raw text (API, TikTok) show nothing for it.
export const HARD_BREAK = '  \n';

const PARAGRAPH_OPEN = '<p>';
const PARAGRAPH_CLOSE = '</p>\n';

// Joins two texts on adjacent lines. A lone newline is a markdown soft break,
// which the Email and Line renderers turn into a space, so a hard break joins
// them when that changes nothing else: rendering the joined text must give
// exactly the two renderings with their boundary paragraphs merged by a
// `<br>`. Anything the seam would change (a list, quote or table swallowing
// the next line, an ordered item or a `===` reshaping the paragraph, emphasis
// markers pairing across the two texts, a backslash before the break) needs a
// blank line to stay apart.
export const lineBreakBetween = (upper, lower) => {
  const upperHtml = md.render(upper);
  const lowerHtml = md.render(lower);
  const joinsParagraphs =
    upperHtml.endsWith(PARAGRAPH_CLOSE) &&
    lowerHtml.startsWith(PARAGRAPH_OPEN) &&
    md.render(`${upper}${HARD_BREAK}${lower}`) ===
      `${upperHtml.slice(0, -PARAGRAPH_CLOSE.length)}<br>\n${lowerHtml.slice(PARAGRAPH_OPEN.length)}`;
  return joinsParagraphs ? HARD_BREAK : '\n\n';
};
