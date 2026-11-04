// The editor stores a hard line break as a backslash followed by a newline.
// markdown-it runs its inline `linkify` rule before the `escape` rule, so a bare
// URL sitting right before that marker swallows the backslash into the match and
// renders an `href` ending in `%5C`, which usually 404s.
//
// Trimming the marker off the match hands it back to the `escape` rule, which
// turns it into the hard break it was meant to be. A run of backslashes with an
// even length is a chain of escaped backslashes, not a break marker, so it stays
// part of the URL.
export default function linkifyHardbreaks(md) {
  const matchAtStart = md.linkify.matchAtStart.bind(md.linkify);

  md.linkify.matchAtStart = text => {
    const match = matchAtStart(text);
    if (!match || text[match.lastIndex] !== '\n') return match;

    const trailingBackslashes = /\\+$/.exec(match.raw)?.[0].length ?? 0;
    if (trailingBackslashes % 2 === 0) return match;

    match.raw = match.raw.slice(0, -1);
    match.text = match.text.slice(0, -1);
    match.url = match.url.slice(0, -1);
    match.lastIndex -= 1;
    return match;
  };
}
