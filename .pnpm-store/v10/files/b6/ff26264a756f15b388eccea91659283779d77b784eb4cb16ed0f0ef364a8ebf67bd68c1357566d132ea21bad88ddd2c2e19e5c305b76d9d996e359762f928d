import { Plugin } from 'prosemirror-state';
import { Decoration, DecorationSet } from 'prosemirror-view';

export default (placeholderText = '') => {
  return new Plugin({
    props: {
      decorations: state => {
        const decorations = [];

        const decorate = (node, pos) => {
          if (state.doc.content.size === 2) {
            decorations.push(
              Decoration.node(pos, pos + node.nodeSize, {
                class: 'empty-node',
                'data-placeholder': placeholderText,
              })
            );
          }
        };

        state.doc.descendants(decorate);

        return DecorationSet.create(state.doc, decorations);
      },
    },
  });
};
