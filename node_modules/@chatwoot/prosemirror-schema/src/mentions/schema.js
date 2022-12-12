import {
  schema,
  MarkdownParser,
  MarkdownSerializer,
} from 'prosemirror-markdown';

import { Schema } from 'prosemirror-model';

const mentionParser = () => ({
  node: 'mention',
  getAttrs: ({ mention }) => {
    const { userId, userFullName } = mention;
    return { userId, userFullName };
  },
});

const markdownSerializer = () => (state, node) => {
  const uri = state.esc(
    `mention://user/${node.attrs.userId}/${encodeURIComponent(node.attrs.userFullName)}`
  );
  const escapedDisplayName = state.esc('@' + (node.attrs.userFullName || ''));

  state.write(`[${escapedDisplayName}](${uri})`);
};

export const addMentionsToMarkdownSerializer = serializer =>
  new MarkdownSerializer(
    { mention: markdownSerializer(), ...serializer.nodes },
    serializer.marks
  );

const mentionNode = {
  attrs: { userFullName: { default: '' }, userId: { default: '' } },
  group: 'inline',
  inline: true,
  selectable: true,
  draggable: true,
  atom: true,
  toDOM: node => [
    'span',
    {
      class: 'prosemirror-mention-node',
      'mention-user-id': node.attrs.userId,
      'mention-user-full-name': node.attrs.userFullName,
    },
    `@${node.attrs.userFullName}`,
  ],
  parseDOM: [
    {
      tag: 'span[mention-user-id][mention-user-full-name]',
      getAttrs: dom => {
        const userId = dom.getAttribute('mention-user-id');
        const userFullName = dom.getAttribute('mention-user-full-name');
        return { userId, userFullName };
      },
    },
  ],
};

const addMentionNodes = nodes => nodes.append({ mention: mentionNode });

export const schemaWithMentions = new Schema({
  nodes: addMentionNodes(schema.spec.nodes),
  marks: schema.spec.marks,
});

export const addMentionsToMarkdownParser = parser => {
  return new MarkdownParser(schemaWithMentions, parser.tokenizer, {
    ...parser.tokens,
    mention: mentionParser(),
  });
};
