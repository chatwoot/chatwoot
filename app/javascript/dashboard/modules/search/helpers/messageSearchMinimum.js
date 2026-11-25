// MESSAGE_SEARCH_MIN_QUERY_LENGTH: a term shorter than the installation's minimum does not search
// messages (0, the default, means no minimum). Contacts, conversations and articles are not affected.
// The backend decides with Ruby's `strip` and `length`, so the term is measured the same way here:
// only ASCII whitespace and NUL are stripped, and characters are counted as code points.
const RUBY_STRIP = /^[\t\n\v\f\r \0]+|[\t\n\v\f\r \0]+$/g;

export const isBelowMessageSearchMinimum = (query, minimum) => {
  const length = Array.from((query || '').replace(RUBY_STRIP, '')).length;
  return length > 0 && length < minimum;
};
