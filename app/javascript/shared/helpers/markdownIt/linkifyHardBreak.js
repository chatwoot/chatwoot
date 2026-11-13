// markdown-it linkifies a bare URL before it reads `\` + newline as a hard
// break, so the `\` ends up in the link. Match the URL without it.
export default function linkifyHardBreakPlugin(md) {
  const matchAtStart = md.linkify.matchAtStart.bind(md.linkify);
  md.linkify.matchAtStart = text => {
    const match = matchAtStart(text);
    if (match && text.startsWith('\\\n', match.lastIndex - 1)) {
      return matchAtStart(text.slice(0, match.lastIndex - 1));
    }
    return match;
  };
}
