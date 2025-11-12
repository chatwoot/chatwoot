export function filterMdToPmSchemaMapping(schema, map) {
  return Object.keys(map).reduce((newMap, key) => {
    const value = map[key];
    const block = value.block || value.node;
    const mark = value.mark;

    if ((block && schema.nodes[block]) || (mark && schema.marks[mark])) {
      newMap[key] = value;
    }
    return newMap;
  }, {});
}

export const baseSchemaToMdMapping = {
  nodes: {
    blockquote: 'blockquote',
    paragraph: 'paragraph',
    code_block: ['code', 'fence'],
    list_item: 'list',
  },
  marks: {
    em: 'emphasis',
    superscript: 'sup',
    strong: 'text',
    link: ['link', 'autolink', 'reference', 'linkify'],
    strike: 'strikethrough',
    code: 'backticks',
  },
};

export const baseNodesMdToPmMapping = {
  blockquote: { block: 'blockquote' },
  paragraph: { block: 'paragraph' },
  softbreak: { node: 'hard_break' },
  hardbreak: { node: 'hard_break' },
  code_block: { block: 'code_block' },
  fence: {
    block: 'code_block',
    // we trim any whitespaces around language definition
    attrs: tok => ({ language: (tok.info && tok.info.trim()) || null }),
  },
  list_item: { block: 'list_item' },
  bullet_list: { block: 'bullet_list' },
  ordered_list: {
    block: 'ordered_list',
    attrs: tok => ({ order: +tok.attrGet('order') || 1 }),
  },
  image: {
    node: 'image',
    getAttrs: (tok) => {
      const src = tok.attrGet('src');
      const heightMatch = src.match(/cw_image_height=(\d+)px/);
      return {
        src,
        title: tok.attrGet('title') || null,
        alt: (tok.children[0] && tok.children[0].content) || null,
        height: heightMatch ? `${heightMatch[1]}px` : null
      };
    },
  },
};

export const baseMarksMdToPmMapping = {
  em: { mark: 'em' },
  sup: { mark: 'superscript' },
  strong: { mark: 'strong' },
  link: {
    mark: 'link',
    attrs: tok => ({
      href: tok.attrGet('href'),
      title: tok.attrGet('title') || null,
    }),
  },
  code_inline: { mark: 'code' },
  s: { mark: 'strike' },
};
