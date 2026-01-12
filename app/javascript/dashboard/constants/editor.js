// Formatting rules for different contexts (channels and special contexts)
// marks: inline formatting (strong, em, code, link, strike)
// nodes: block structures (bulletList, orderedList, codeBlock, blockquote)
export const FORMATTING = {
  // Channel formatting
  'Channel::Email': {
    marks: ['strong', 'em', 'code', 'link'],
    nodes: ['bulletList', 'orderedList', 'codeBlock', 'blockquote', 'image'],
    menu: [
      'strong',
      'em',
      'code',
      'link',
      'bulletList',
      'orderedList',
      'undo',
      'redo',
    ],
  },
  'Channel::WebWidget': {
    marks: ['strong', 'em', 'code', 'link', 'strike'],
    nodes: ['bulletList', 'orderedList', 'codeBlock', 'blockquote', 'image'],
    menu: [
      'strong',
      'em',
      'code',
      'link',
      'strike',
      'bulletList',
      'orderedList',
      'undo',
      'redo',
    ],
  },
  'Channel::Api': {
    marks: ['strong', 'em'],
    nodes: [],
    menu: ['strong', 'em', 'undo', 'redo'],
  },
  'Channel::FacebookPage': {
    marks: ['strong', 'em', 'code', 'strike'],
    nodes: ['bulletList', 'orderedList', 'codeBlock'],
    menu: [
      'strong',
      'em',
      'code',
      'strike',
      'bulletList',
      'orderedList',
      'undo',
      'redo',
    ],
  },
  'Channel::TwitterProfile': {
    marks: [],
    nodes: [],
    menu: [],
  },
  'Channel::TwilioSms': {
    marks: [],
    nodes: [],
    menu: [],
  },
  'Channel::Sms': {
    marks: [],
    nodes: [],
    menu: [],
  },
  'Channel::Whatsapp': {
    marks: ['strong', 'em', 'code', 'strike'],
    nodes: ['bulletList', 'orderedList', 'codeBlock'],
    menu: [
      'strong',
      'em',
      'code',
      'strike',
      'bulletList',
      'orderedList',
      'undo',
      'redo',
    ],
  },
  'Channel::Line': {
    marks: ['strong', 'em', 'code', 'strike'],
    nodes: ['codeBlock'],
    menu: ['strong', 'em', 'code', 'strike', 'undo', 'redo'],
  },
  'Channel::Telegram': {
    marks: ['strong', 'em', 'link', 'code'],
    nodes: [],
    menu: ['strong', 'em', 'link', 'code', 'undo', 'redo'],
  },
  'Channel::Instagram': {
    marks: ['strong', 'em', 'code', 'strike'],
    nodes: ['bulletList', 'orderedList'],
    menu: [
      'strong',
      'em',
      'code',
      'bulletList',
      'orderedList',
      'strike',
      'undo',
      'redo',
    ],
  },
  'Channel::Voice': {
    marks: [],
    nodes: [],
    menu: [],
  },
  'Channel::Tiktok': {
    marks: [],
    nodes: [],
    menu: [],
  },
  // Special contexts (not actual channels)
  'Context::Default': {
    marks: ['strong', 'em', 'code', 'link', 'strike'],
    nodes: ['bulletList', 'orderedList', 'codeBlock', 'blockquote'],
    menu: [
      'strong',
      'em',
      'code',
      'link',
      'strike',
      'bulletList',
      'orderedList',
      'undo',
      'redo',
    ],
  },
  'Context::MessageSignature': {
    marks: ['strong', 'em', 'link'],
    nodes: ['image'],
    menu: ['strong', 'em', 'link', 'undo', 'redo', 'imageUpload'],
  },
  'Context::InboxSettings': {
    marks: ['strong', 'em', 'link'],
    nodes: [],
    menu: ['strong', 'em', 'link', 'undo', 'redo'],
  },
  'Context::Plain': {
    marks: [],
    nodes: [],
    menu: [],
  },
};

// Editor menu options for Full Editor
export const ARTICLE_EDITOR_MENU_OPTIONS = [
  'strong',
  'em',
  'link',
  'undo',
  'redo',
  'bulletList',
  'orderedList',
  'h1',
  'h2',
  'h3',
  'imageUpload',
  'code',
];

/**
 * Markdown formatting patterns for stripping unsupported formatting.
 *
 * Maps camelCase type names to ProseMirror snake_case schema names.
 * Order matters: codeBlock before code to avoid partial matches.
 */
export const MARKDOWN_PATTERNS = [
  // --- BLOCK NODES ---
  {
    type: 'codeBlock', // PM: code_block, eg: ```js\ncode\n```
    patterns: [
      { pattern: /`{3}(?:\w+)?\n?([\s\S]*?)`{3}/g, replacement: '$1' },
    ],
  },
  {
    type: 'blockquote', // PM: blockquote, eg: > quote
    patterns: [{ pattern: /^> ?/gm, replacement: '' }],
  },
  {
    type: 'bulletList', // PM: bullet_list, eg: - item
    patterns: [{ pattern: /^[\t ]*[-*+]\s+/gm, replacement: '' }],
  },
  {
    type: 'orderedList', // PM: ordered_list, eg: 1. item
    patterns: [{ pattern: /^[\t ]*\d+\.\s+/gm, replacement: '' }],
  },
  {
    type: 'heading', // PM: heading, eg: ## Heading
    patterns: [{ pattern: /^#{1,6}\s+/gm, replacement: '' }],
  },
  {
    type: 'horizontalRule', // PM: horizontal_rule, eg: ---
    patterns: [{ pattern: /^(?:---|___|\*\*\*)\s*$/gm, replacement: '' }],
  },
  {
    type: 'image', // PM: image, eg: ![alt](url)
    patterns: [{ pattern: /!\[([^\]]*)\]\([^)]+\)/g, replacement: '$1' }],
  },
  {
    type: 'hardBreak', // PM: hard_break, eg: line\\\n or line  \n
    patterns: [
      { pattern: /\\\n/g, replacement: '\n' },
      { pattern: / {2,}\n/g, replacement: '\n' },
    ],
  },
  // --- INLINE MARKS ---
  {
    type: 'strong', // PM: strong, eg: **bold** or __bold__
    patterns: [
      { pattern: /\*\*(.+?)\*\*/g, replacement: '$1' },
      { pattern: /__(.+?)__/g, replacement: '$1' },
    ],
  },
  {
    type: 'em', // PM: em, eg: *italic* or _italic_
    patterns: [
      { pattern: /(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)/g, replacement: '$1' },
      // Match _text_ only at word boundaries (whitespace/string start/end)
      // Preserves underscores in URLs (e.g., https://example.com/path_name) and variable names
      {
        pattern: /(?<=^|[\s])_([^_\s][^_]*[^_\s]|[^_\s])_(?=$|[\s])/g,
        replacement: '$1',
      },
    ],
  },
  {
    type: 'strike', // PM: strike, eg: ~~strikethrough~~
    patterns: [{ pattern: /~~(.+?)~~/g, replacement: '$1' }],
  },
  {
    type: 'code', // PM: code, eg: `inline code`
    patterns: [{ pattern: /`([^`]+)`/g, replacement: '$1' }],
  },
  {
    type: 'link', // PM: link
    patterns: [
      { pattern: /\[([^\]]+)\]\([^)]+\)/g, replacement: '$1' }, // [text](url) -> text
      { pattern: /<([a-zA-Z][a-zA-Z0-9+.-]*:[^\s>]+)>/g, replacement: '$1' }, // <https://...>, <mailto:...>, <tel:...>, <ftp://...>, etc
      { pattern: /<([^\s@]+@[^\s@>]+)>/g, replacement: '$1' }, // <user@example.com> -> user@example.com
    ],
  },
];

// Editor image resize options for Message Editor
export const MESSAGE_EDITOR_IMAGE_RESIZES = [
  {
    name: 'Small',
    height: '24px',
  },
  {
    name: 'Medium',
    height: '48px',
  },
  {
    name: 'Large',
    height: '72px',
  },
  {
    name: 'Original Size',
    height: 'auto',
  },
];
