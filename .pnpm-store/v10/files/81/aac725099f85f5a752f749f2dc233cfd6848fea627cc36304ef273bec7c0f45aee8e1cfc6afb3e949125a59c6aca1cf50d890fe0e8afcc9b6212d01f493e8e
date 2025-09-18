import {
  schema,
  MarkdownParser,
  MarkdownSerializer,
} from 'prosemirror-markdown';

import { Schema } from 'prosemirror-model';

const mentionParser = () => ({
  node: 'mention',
  getAttrs: ({ mention }) => {
    const { userId, userFullName, mentionType = 'user' } = mention;
    const attrs = { userId, userFullName, mentionType };
    
    return attrs;
  },
});

const markdownSerializer = () => (state, node) => {
  const userId = String(node.attrs.userId || '');
  const displayName = node.attrs.userFullName || '';
  const mentionType = node.attrs.mentionType || 'user';

  const uri = state.esc(
    `mention://${mentionType}/${userId}/${encodeURIComponent(displayName)}`
  );
  
  const escapedDisplayName = state.esc(`@${displayName}`);

  state.write(`[${escapedDisplayName}](${uri})`);
};

export const addMentionsToMarkdownSerializer = (serializer) => new MarkdownSerializer(
  { mention: markdownSerializer(), ...serializer.nodes },
  serializer.marks,
);

const mentionNode = {
  attrs: { 
    userFullName: { default: '' }, 
    userId: { default: '' },
    mentionType: { default: 'user' }
  },
  group: 'inline',
  inline: true,
  selectable: true,
  draggable: true,
  atom: true,
  toDOM: (node) => [
    'span',
    {
      class: 'prosemirror-mention-node',
      'mention-user-id': node.attrs.userId,
      'mention-user-full-name': node.attrs.userFullName,
      'mention-type': node.attrs.mentionType,
    },
    `@${node.attrs.userFullName}`,
  ],
  parseDOM: [
    {
      tag: 'span[mention-user-id][mention-user-full-name]',
      getAttrs: (dom) => {
        const userId = dom.getAttribute('mention-user-id');
        const userFullName = dom.getAttribute('mention-user-full-name');
        const mentionType = dom.getAttribute('mention-type') || 'user';
        const attrs = { userId, userFullName, mentionType };
        
        return attrs;
      },
    },
  ],
};

const addMentionNodes = (nodes) => nodes.append({ mention: mentionNode });

export const schemaWithMentions = new Schema({
  nodes: addMentionNodes(schema.spec.nodes),
  marks: schema.spec.marks,
});

export const addMentionsToMarkdownParser = (parser) => new MarkdownParser(schemaWithMentions, parser.tokenizer, {
  ...parser.tokens,
  mention: mentionParser(),
});
