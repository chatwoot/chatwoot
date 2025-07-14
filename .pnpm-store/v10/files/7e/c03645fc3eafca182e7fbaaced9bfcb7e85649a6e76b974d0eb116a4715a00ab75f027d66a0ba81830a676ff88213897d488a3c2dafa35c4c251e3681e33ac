import { MarkdownSerializer as MarkdownSerializerBase } from 'prosemirror-markdown';

import {
  mention,
  blockquote,
  code_block,
  bullet_list,
  ordered_list,
  list_item,
  paragraph,
  image,
  hard_break,
  text,
  em,
  strike,
  strong,
  link,
  code,
} from './serializer';

export const MessageMarkdownSerializer = new MarkdownSerializerBase(
  {
    mention,
    blockquote,
    code_block,
    bullet_list,
    ordered_list,
    list_item,
    paragraph,
    image,
    hard_break,
    text,
  },
  {
    em,
    strike,
    strong,
    link,
    code,
  }
);
