/**
 * This file is a modified version of prosemirror-suggestions
 * https://github.com/quartzy/prosemirror-suggestions/blob/master/src/suggestions.js
 */

import { Plugin, PluginKey } from 'prosemirror-state';
import { Decoration, DecorationSet } from 'prosemirror-view';

export const triggerCharacters = char => $position => {
  const regexp = new RegExp(`(?:^)?${char}[^\\s${char}]*`, 'g');

  const textFrom = $position.before();
  const textTo = $position.end();

  const text = $position.doc.textBetween(textFrom, textTo, '\0', '\0');

  let match;

  // eslint-disable-next-line
  while ((match = regexp.exec(text))) {
    const prefix = match.input.slice(Math.max(0, match.index - 1), match.index);
    if (!/^[\s\0]?$/.test(prefix)) {
      // eslint-disable-next-line
      continue;
    }

    const from = match.index + $position.start();
    let to = from + match[0].length;

    if (from < $position.pos && to >= $position.pos) {
      return { range: { from, to }, text: match[0] };
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
