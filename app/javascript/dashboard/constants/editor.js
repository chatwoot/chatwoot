// Formatting rules for different contexts (channels and special contexts)
// marks: inline formatting (strong, em, code, link, strike)
// nodes: block structures (bulletList, orderedList, codeBlock, blockquote)
export const FORMATTING = {
  // Channel formatting
  'Channel::Email': {
    marks: ['strong', 'em', 'code', 'link'],
    nodes: ['bulletList', 'orderedList', 'codeBlock', 'blockquote'],
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
  'Channel::Api': {
    marks: [],
    nodes: [],
    menu: [],
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
    nodes: [],
    menu: ['strong', 'em', 'link', 'undo', 'redo', 'imageUpload'],
  },
  'Context::InboxSettings': {
    marks: ['strong', 'em', 'link'],
    nodes: [],
    menu: ['strong', 'em', 'link', 'undo', 'redo'],
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
