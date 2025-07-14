/**
 * This file is a modified version of prosemirror-suggestions
 * https://github.com/quartzy/prosemirror-suggestions/blob/master/src/suggestions.js
 */

import { Plugin, PluginKey } from 'prosemirror-state';
import { Decoration, DecorationSet } from 'prosemirror-view';

/**
 * Creates a function to detect if the trigger character followed by a specified number of characters
 * has been typed, starting from a new word, after a space, or after a newline.
 * @param {string} char - The trigger character to detect.
 * @param {number} [minChars=0] - The minimum number of characters that should follow the trigger character.
 * @returns {Function} A function that takes a position object and returns the match if the condition is met.
 */
export const triggerCharacters = (char, minChars = 0) => $position => {
  // Regular expression to find occurrences of 'char' followed by at least 'minChars' non-space characters.
  // It matches these sequences starting from the beginning of the text or after a space.
  const regexp = new RegExp(`(?:^)?${char}[^\\s${char}]{${minChars},}`, 'g');

  // Get the position before the current cursor position in the document.
  const textFrom = $position.before();
  // Get the position at the end of the current node.
  const textTo = $position.end();

  // Get the text between the start of the node and the cursor position.
  const text = $position.doc.textBetween(textFrom, textTo, '\0', '\0');

  let match;

  // eslint-disable-next-line
  while ((match = regexp.exec(text))) {
    // Check if the character before the match is a space, start of string, or null character
    const prefix = match.input.slice(Math.max(0, match.index - 1), match.index);
    if (!/^[\s\0]?$/.test(prefix)) {
      // If the prefix is not empty, space, or null, skip this match
      // eslint-disable-next-line
      continue;
    }

    const from = match.index + $position.start();
    const to = from + match[0].length;

    if (from < $position.pos && to >= $position.pos) {
      const fullMatch = match[0];
      // Remove trigger char and trim
      const trimmedText = fullMatch ? fullMatch.slice(char.length) : '';
      return { range: { from, to }, text: trimmedText };
    }
  }
  return null;
};

export const suggestionsPlugin = ({
  matcher,
  suggestionClass = 'prosemirror-mention-node',
  onEnter = () => false,
  onChange = () => false,
  onExit = () => false,
  onKeyDown = () => false,
}) => {
  return new Plugin({
    key: new PluginKey('mentions'),

    view() {
      return {
        update: (view, prevState) => {
          const prev = this.key.getState(prevState);
          const next = this.key.getState(view.state);

          const moved =
            prev.active && next.active && prev.range.from !== next.range.from;
          const started = !prev.active && next.active;
          const stopped = prev.active && !next.active;
          const changed = !started && !stopped && prev.text !== next.text;

          if (stopped || moved)
            onExit({ view, range: prev.range, text: prev.text });
          if (changed && !moved)
            onChange({ view, range: next.range, text: next.text });
          if (started || moved)
            onEnter({ view, range: next.range, text: next.text });
        },
      };
    },

    state: {
      init() {
        return {
          active: false,
          range: {},
          text: null,
        };
      },

      apply(tr, prev) {
        const { selection } = tr;
        const next = { ...prev };

        if (selection.from === selection.to) {
          if (
            selection.from < prev.range.from ||
            selection.from > prev.range.to
          ) {
            next.active = false;
          }

          const $position = selection.$from;
          const match = matcher($position);

          if (match) {
            next.active = true;
            next.range = match.range;
            next.text = match.text;
          } else {
            next.active = false;
          }
        } else {
          next.active = false;
        }

        if (!next.active) {
          next.range = {};
          next.text = null;
        }

        return next;
      },
    },

    props: {
      handleKeyDown(view, event) {
        const { active } = this.getState(view.state);

        if (!active) return false;

        return onKeyDown({ view, event });
      },
      decorations(editorState) {
        const { active, range } = this.getState(editorState);

        if (!active) return null;

        return DecorationSet.create(editorState.doc, [
          Decoration.inline(range.from, range.to, {
            nodeName: 'span',
            class: suggestionClass,
          }),
        ]);
      },
    },
  });
};
