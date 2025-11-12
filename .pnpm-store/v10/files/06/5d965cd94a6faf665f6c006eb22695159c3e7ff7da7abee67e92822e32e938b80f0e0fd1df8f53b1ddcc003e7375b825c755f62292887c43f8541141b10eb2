import MarkdownIt from 'markdown-it';
import { MarkdownParser } from 'prosemirror-markdown';
import {
  baseSchemaToMdMapping,
  baseNodesMdToPmMapping,
  baseMarksMdToPmMapping,
  filterMdToPmSchemaMapping,
} from './parser';

export const messageSchemaToMdMapping = {
  nodes: { ...baseSchemaToMdMapping.nodes },
  marks: { ...baseSchemaToMdMapping.marks },
};

export const messageMdToPmMapping = {
  ...baseNodesMdToPmMapping,
  ...baseMarksMdToPmMapping,
  mention: {
    node: 'mention',
    getAttrs: ({ mention }) => {
      const { userId, userFullName, mentionType = 'user' } = mention;
      const attrs = { userId, userFullName, mentionType };
      
      return attrs;
    },
  },
  tools: {
    node: 'tools',
    getAttrs: ({ tools }) => {
      const { id, name } = tools;
      return { id, name };
    },
  },
};

const md = MarkdownIt('commonmark', {
  html: false,
  linkify: false,
});

md.enable([
  // Process html entity - &#123;, &#xAF;, &quot;, ...
  'entity',
  // Process escaped chars and hardbreaks
  'escape',
]);

md.disable(['table', 'hr', 'heading', 'lheading'], true);

export class MessageMarkdownTransformer {
  constructor(schema, tokenizer = md) {
    // Enable markdown plugins based on schema
    ['nodes', 'marks'].forEach(key => {
      for (const idx in messageSchemaToMdMapping[key]) {
        if (schema[key][idx]) {
          tokenizer.enable(messageSchemaToMdMapping[key][idx]);
        }
      }
    });

    this.markdownParser = new MarkdownParser(
      schema,
      tokenizer,
      filterMdToPmSchemaMapping(schema, messageMdToPmMapping)
    );
  }
  encode(_node) {
    throw new Error('This is not implemented yet');
  }

  parse(content) {
    return this.markdownParser.parse(content);
  }
}
