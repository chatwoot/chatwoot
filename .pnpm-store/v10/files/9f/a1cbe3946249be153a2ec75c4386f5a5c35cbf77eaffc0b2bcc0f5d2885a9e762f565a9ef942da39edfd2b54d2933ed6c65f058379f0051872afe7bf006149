import { orderedList, bulletList, listItem } from 'prosemirror-schema-list';
import { schema } from 'prosemirror-markdown';

import { Schema } from 'prosemirror-model';

export const messageSchema = new Schema({
  nodes: {
    doc: schema.spec.nodes.get('doc'),
    paragraph: schema.spec.nodes.get('paragraph'),
    blockquote: schema.spec.nodes.get('blockquote'),
    code_block: schema.spec.nodes.get('code_block'),
    text: schema.spec.nodes.get('text'),
    hard_break: schema.spec.nodes.get('hard_break'),
    image: {
      ...schema.spec.nodes.get('image'),
      attrs: {
        ...schema.spec.nodes.get('image').attrs,
        height: {default: null}
      },
      parseDOM: [{
        tag: 'img[src]',
        getAttrs: dom => ({
          src: dom.getAttribute('src'),
          title: dom.getAttribute('title'),
          alt: dom.getAttribute('alt'),
          height: parseInt(dom.style.height)
        })
      }],
      toDOM: node => {
        const attrs = {
          src: node.attrs.src,
          alt: node.attrs.alt,
          height: node.attrs.height
        };
        if (node.attrs.height) {
          attrs.style = `height: ${node.attrs.height}`;
        }
        return ["img", attrs];
      }
    }, 
    ordered_list: Object.assign(orderedList, {
      content: 'list_item+',
      group: 'block',
    }),
    bullet_list: Object.assign(bulletList, {
      content: 'list_item+',
      group: 'block',
    }),
    list_item: Object.assign(listItem, { content: 'paragraph block*' }),
    mention: {
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
      toDOM: node => [
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
          getAttrs: dom => {
            const userId = dom.getAttribute('mention-user-id');
            const userFullName = dom.getAttribute('mention-user-full-name');
            const mentionType = dom.getAttribute('mention-type') || 'user';
            
            return { userId, userFullName, mentionType };
          },
        },
      ],
    },
    tools: {
      attrs: { id: { default: '' }, name: { default: '' } },
      group: 'inline',
      inline: true,
      selectable: true,
      draggable: true,
      atom: true,
      toDOM: node => [
        'span',
        {
          class: 'prosemirror-tools-node',
          'tool-id': node.attrs.id,
          'tool-name': node.attrs.name,
        },
        `@${node.attrs.name}`,
      ],
      parseDOM: [
        {
          tag: 'span[tool-id][tool-name]',
          getAttrs: dom => {
            const id = dom.getAttribute('tool-id');
            const name = dom.getAttribute('tool-name');
            return { id, name };
          },
        },
      ],
    },
  },
  marks: {
    link: schema.spec.marks.get('link'),
    em: schema.spec.marks.get('em'),
    strong: schema.spec.marks.get('strong'),
    code: schema.spec.marks.get('code'),
    strike: {
      parseDOM: [
        { tag: 's' },
        { tag: 'del' },
        { tag: 'strike' },
        {
          style: 'text-decoration',
          getAttrs: value => value === 'line-through',
        },
      ],
      toDOM: () => ['s', 0],
    },
  },
});
