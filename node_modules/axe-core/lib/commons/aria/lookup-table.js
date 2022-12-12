// @deprecated use standards object instead
import implicitHtmlRoles from '../standards/implicit-html-roles';

const isNull = value => value === null;
const isNotNull = value => value !== null;

const lookupTable = {};

lookupTable.attributes = {
  'aria-activedescendant': {
    type: 'idref',
    allowEmpty: true,
    unsupported: false
  },
  'aria-atomic': {
    type: 'boolean',
    values: ['true', 'false'],
    unsupported: false
  },
  'aria-autocomplete': {
    type: 'nmtoken',
    values: ['inline', 'list', 'both', 'none'],
    unsupported: false
  },
  'aria-busy': {
    type: 'boolean',
    values: ['true', 'false'],
    unsupported: false
  },
  'aria-checked': {
    type: 'nmtoken',
    values: ['true', 'false', 'mixed', 'undefined'],
    unsupported: false
  },
  'aria-colcount': {
    type: 'int',
    unsupported: false
  },
  'aria-colindex': {
    type: 'int',
    unsupported: false
  },
  'aria-colspan': {
    type: 'int',
    unsupported: false
  },
  'aria-controls': {
    type: 'idrefs',
    allowEmpty: true,
    unsupported: false
  },
  'aria-current': {
    type: 'nmtoken',
    allowEmpty: true,
    values: ['page', 'step', 'location', 'date', 'time', 'true', 'false'],
    unsupported: false
  },
  'aria-describedby': {
    type: 'idrefs',
    allowEmpty: true,
    unsupported: false
  },
  'aria-describedat': {
    unsupported: true,
    unstandardized: true
  },
  'aria-details': {
    type: 'idref',
    allowEmpty: true,
    unsupported: false
  },
  'aria-disabled': {
    type: 'boolean',
    values: ['true', 'false'],
    unsupported: false
  },
  'aria-dropeffect': {
    type: 'nmtokens',
    values: ['copy', 'move', 'reference', 'execute', 'popup', 'none'],
    unsupported: false
  },
  'aria-errormessage': {
    type: 'idref',
    allowEmpty: true,
    unsupported: false
  },
  'aria-expanded': {
    type: 'nmtoken',
    values: ['true', 'false', 'undefined'],
    unsupported: false
  },
  'aria-flowto': {
    type: 'idrefs',
    allowEmpty: true,
    unsupported: false
  },
  'aria-grabbed': {
    type: 'nmtoken',
    values: ['true', 'false', 'undefined'],
    unsupported: false
  },
  'aria-haspopup': {
    type: 'nmtoken',
    allowEmpty: true,
    values: ['true', 'false', 'menu', 'listbox', 'tree', 'grid', 'dialog'],
    unsupported: false
  },
  'aria-hidden': {
    type: 'boolean',
    values: ['true', 'false'],
    unsupported: false
  },
  'aria-invalid': {
    type: 'nmtoken',
    allowEmpty: true,
    values: ['true', 'false', 'spelling', 'grammar'],
    unsupported: false
  },
  'aria-keyshortcuts': {
    type: 'string',
    allowEmpty: true,
    unsupported: false
  },
  'aria-label': {
    type: 'string',
    allowEmpty: true,
    unsupported: false
  },
  'aria-labelledby': {
    type: 'idrefs',
    allowEmpty: true,
    unsupported: false
  },
  'aria-level': {
    type: 'int',
    unsupported: false
  },
  'aria-live': {
    type: 'nmtoken',
    values: ['off', 'polite', 'assertive'],
    unsupported: false
  },
  'aria-modal': {
    type: 'boolean',
    values: ['true', 'false'],
    unsupported: false
  },
  'aria-multiline': {
    type: 'boolean',
    values: ['true', 'false'],
    unsupported: false
  },
  'aria-multiselectable': {
    type: 'boolean',
    values: ['true', 'false'],
    unsupported: false
  },
  'aria-orientation': {
    type: 'nmtoken',
    values: ['horizontal', 'vertical'],
    unsupported: false
  },
  'aria-owns': {
    type: 'idrefs',
    allowEmpty: true,
    unsupported: false
  },
  'aria-placeholder': {
    type: 'string',
    allowEmpty: true,
    unsupported: false
  },
  'aria-posinset': {
    type: 'int',
    unsupported: false
  },
  'aria-pressed': {
    type: 'nmtoken',
    values: ['true', 'false', 'mixed', 'undefined'],
    unsupported: false
  },
  'aria-readonly': {
    type: 'boolean',
    values: ['true', 'false'],
    unsupported: false
  },
  'aria-relevant': {
    type: 'nmtokens',
    values: ['additions', 'removals', 'text', 'all'],
    unsupported: false
  },
  'aria-required': {
    type: 'boolean',
    values: ['true', 'false'],
    unsupported: false
  },
  'aria-roledescription': {
    type: 'string',
    allowEmpty: true,
    unsupported: false
  },
  'aria-rowcount': {
    type: 'int',
    unsupported: false
  },
  'aria-rowindex': {
    type: 'int',
    unsupported: false
  },
  'aria-rowspan': {
    type: 'int',
    unsupported: false
  },
  'aria-selected': {
    type: 'nmtoken',
    values: ['true', 'false', 'undefined'],
    unsupported: false
  },
  'aria-setsize': {
    type: 'int',
    unsupported: false
  },
  'aria-sort': {
    type: 'nmtoken',
    values: ['ascending', 'descending', 'other', 'none'],
    unsupported: false
  },
  'aria-valuemax': {
    type: 'decimal',
    unsupported: false
  },
  'aria-valuemin': {
    type: 'decimal',
    unsupported: false
  },
  'aria-valuenow': {
    type: 'decimal',
    unsupported: false
  },
  'aria-valuetext': {
    type: 'string',
    unsupported: false
  }
};

lookupTable.globalAttributes = [
  'aria-atomic',
  'aria-busy',
  'aria-controls',
  'aria-current',
  'aria-describedby',
  'aria-details',
  'aria-disabled',
  'aria-dropeffect',
  'aria-flowto',
  'aria-grabbed',
  'aria-haspopup',
  'aria-hidden',
  'aria-invalid',
  'aria-keyshortcuts',
  'aria-label',
  'aria-labelledby',
  'aria-live',
  'aria-owns',
  'aria-relevant',
  'aria-roledescription'
];

lookupTable.role = {
  // valid roles below
  alert: {
    type: 'widget',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  alertdialog: {
    type: 'widget',
    attributes: {
      allowed: ['aria-expanded', 'aria-modal', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['dialog', 'section']
  },
  application: {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage', 'aria-activedescendant']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: [
      'article',
      'audio',
      'embed',
      'iframe',
      'object',
      'section',
      'svg',
      'video'
    ]
  },
  article: {
    type: 'structure',
    attributes: {
      allowed: [
        'aria-expanded',
        'aria-posinset',
        'aria-setsize',
        'aria-errormessage'
      ]
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: ['article'],
    unsupported: false
  },
  banner: {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: ['header'],
    unsupported: false,
    allowedElements: ['section']
  },
  button: {
    type: 'widget',
    attributes: {
      allowed: ['aria-expanded', 'aria-pressed', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: null,
    implicit: [
      'button',
      'input[type="button"]',
      'input[type="image"]',
      'input[type="reset"]',
      'input[type="submit"]',
      'summary'
    ],
    unsupported: false,
    allowedElements: [
      {
        nodeName: 'a',
        attributes: {
          href: isNotNull
        }
      }
    ]
  },
  cell: {
    type: 'structure',
    attributes: {
      allowed: [
        'aria-colindex',
        'aria-colspan',
        'aria-rowindex',
        'aria-rowspan',
        'aria-errormessage'
      ]
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: ['row'],
    implicit: ['td', 'th'],
    unsupported: false
  },
  checkbox: {
    type: 'widget',
    attributes: {
      allowed: [
        'aria-checked',
        'aria-required',
        'aria-readonly',
        'aria-errormessage'
      ]
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: null,
    implicit: ['input[type="checkbox"]'],
    unsupported: false,
    allowedElements: ['button']
  },
  columnheader: {
    type: 'structure',
    attributes: {
      allowed: [
        'aria-colindex',
        'aria-colspan',
        'aria-expanded',
        'aria-rowindex',
        'aria-rowspan',
        'aria-required',
        'aria-readonly',
        'aria-selected',
        'aria-sort',
        'aria-errormessage'
      ]
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: ['row'],
    implicit: ['th'],
    unsupported: false
  },
  combobox: {
    type: 'composite',
    attributes: {
      allowed: [
        'aria-autocomplete',
        'aria-required',
        'aria-activedescendant',
        'aria-orientation',
        'aria-errormessage'
      ],
      required: ['aria-expanded']
    },
    owned: {
      all: ['listbox', 'tree', 'grid', 'dialog', 'textbox']
    },
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: [
      {
        nodeName: 'input',
        properties: {
          type: ['text', 'search', 'tel', 'url', 'email']
        }
      }
    ]
  },
  command: {
    nameFrom: ['author'],
    type: 'abstract',
    unsupported: false
  },
  complementary: {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: ['aside'],
    unsupported: false,
    allowedElements: ['section']
  },
  composite: {
    nameFrom: ['author'],
    type: 'abstract',
    unsupported: false
  },
  contentinfo: {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: ['footer'],
    unsupported: false,
    allowedElements: ['section']
  },
  definition: {
    type: 'structure',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: ['dd', 'dfn'],
    unsupported: false
  },
  dialog: {
    type: 'widget',
    attributes: {
      allowed: ['aria-expanded', 'aria-modal', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: ['dialog'],
    unsupported: false,
    allowedElements: ['section']
  },
  directory: {
    type: 'structure',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: null,
    unsupported: false,
    allowedElements: ['ol', 'ul']
  },
  document: {
    type: 'structure',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: ['body'],
    unsupported: false,
    allowedElements: ['article', 'embed', 'iframe', 'object', 'section', 'svg']
  },
  'doc-abstract': {
    type: 'section',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-acknowledgments': {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-afterword': {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-appendix': {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-backlink': {
    type: 'link',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: null,
    unsupported: false,
    allowedElements: [
      {
        nodeName: 'a',
        attributes: {
          href: isNotNull
        }
      }
    ]
  },
  'doc-biblioentry': {
    type: 'listitem',
    attributes: {
      allowed: [
        'aria-expanded',
        'aria-level',
        'aria-posinset',
        'aria-setsize',
        'aria-errormessage'
      ]
    },
    owned: null,
    nameFrom: ['author'],
    context: ['doc-bibliography'],
    unsupported: false,
    allowedElements: ['li']
  },
  'doc-bibliography': {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: {
      one: ['doc-biblioentry']
    },
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-biblioref': {
    type: 'link',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: null,
    unsupported: false,
    allowedElements: [
      {
        nodeName: 'a',
        attributes: {
          href: isNotNull
        }
      }
    ]
  },
  'doc-chapter': {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-colophon': {
    type: 'section',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-conclusion': {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-cover': {
    type: 'img',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false
  },
  'doc-credit': {
    type: 'section',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-credits': {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-dedication': {
    type: 'section',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-endnote': {
    type: 'listitem',
    attributes: {
      allowed: [
        'aria-expanded',
        'aria-level',
        'aria-posinset',
        'aria-setsize',
        'aria-errormessage'
      ]
    },
    owned: null,
    namefrom: ['author'],
    context: ['doc-endnotes'],
    unsupported: false,
    allowedElements: ['li']
  },
  'doc-endnotes': {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: {
      one: ['doc-endnote']
    },
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-epigraph': {
    type: 'section',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false
  },
  'doc-epilogue': {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-errata': {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-example': {
    type: 'section',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['aside', 'section']
  },
  'doc-footnote': {
    type: 'section',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['aside', 'footer', 'header']
  },
  'doc-foreword': {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-glossary': {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: ['term', 'definition'],
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['dl']
  },
  'doc-glossref': {
    type: 'link',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    namefrom: ['author', 'contents'],
    context: null,
    unsupported: false,
    allowedElements: [
      {
        nodeName: 'a',
        attributes: {
          href: isNotNull
        }
      }
    ]
  },
  'doc-index': {
    type: 'navigation',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['nav', 'section']
  },
  'doc-introduction': {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-noteref': {
    type: 'link',
    attributes: {
      allowed: ['aria-expanded']
    },
    owned: null,
    namefrom: ['author', 'contents'],
    context: null,
    unsupported: false,
    allowedElements: [
      {
        nodeName: 'a',
        attributes: {
          href: isNotNull
        }
      }
    ]
  },
  'doc-notice': {
    type: 'note',
    attributes: {
      allowed: ['aria-expanded']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-pagebreak': {
    type: 'separator',
    attributes: {
      allowed: ['aria-expanded']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['hr']
  },
  'doc-pagelist': {
    type: 'navigation',
    attributes: {
      allowed: ['aria-expanded']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['nav', 'section']
  },
  'doc-part': {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-preface': {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-prologue': {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-pullquote': {
    type: 'none',
    attributes: {
      allowed: ['aria-expanded']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['aside', 'section']
  },
  'doc-qna': {
    type: 'section',
    attributes: {
      allowed: ['aria-expanded']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  'doc-subtitle': {
    type: 'sectionhead',
    attributes: {
      allowed: ['aria-expanded']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: {
      nodeName: ['h1', 'h2', 'h3', 'h4', 'h5', 'h6']
    }
  },
  'doc-tip': {
    type: 'note',
    attributes: {
      allowed: ['aria-expanded']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['aside']
  },
  'doc-toc': {
    type: 'navigation',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    namefrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['nav', 'section']
  },
  feed: {
    type: 'structure',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: {
      one: ['article']
    },
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['article', 'aside', 'section']
  },
  figure: {
    type: 'structure',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: null,
    implicit: ['figure'],
    unsupported: false
  },
  form: {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: ['form'],
    unsupported: false
  },
  grid: {
    type: 'composite',
    attributes: {
      allowed: [
        'aria-activedescendant',
        'aria-expanded',
        'aria-colcount',
        'aria-level',
        'aria-multiselectable',
        'aria-readonly',
        'aria-rowcount',
        'aria-errormessage'
      ]
    },
    owned: {
      one: ['rowgroup', 'row']
    },
    nameFrom: ['author'],
    context: null,
    implicit: ['table'],
    unsupported: false
  },
  gridcell: {
    type: 'widget',
    attributes: {
      allowed: [
        'aria-colindex',
        'aria-colspan',
        'aria-expanded',
        'aria-rowindex',
        'aria-rowspan',
        'aria-selected',
        'aria-readonly',
        'aria-required',
        'aria-errormessage'
      ]
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: ['row'],
    implicit: ['td', 'th'],
    unsupported: false
  },
  group: {
    type: 'structure',
    attributes: {
      allowed: ['aria-activedescendant', 'aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: ['details', 'optgroup'],
    unsupported: false,
    allowedElements: [
      'dl',
      'figcaption',
      'fieldset',
      'figure',
      'footer',
      'header',
      'ol',
      'ul'
    ]
  },
  heading: {
    type: 'structure',
    attributes: {
      required: ['aria-level'],
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: null,
    implicit: ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'],
    unsupported: false
  },
  img: {
    type: 'structure',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: ['img'],
    unsupported: false,
    allowedElements: ['embed', 'iframe', 'object', 'svg']
  },
  input: {
    nameFrom: ['author'],
    type: 'abstract',
    unsupported: false
  },
  landmark: {
    nameFrom: ['author'],
    type: 'abstract',
    unsupported: false
  },
  link: {
    type: 'widget',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: null,
    implicit: ['a[href]', 'area[href]'],
    unsupported: false,
    allowedElements: [
      'button',
      {
        nodeName: 'input',
        properties: {
          type: ['image', 'button']
        }
      }
    ]
  },
  list: {
    type: 'structure',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: {
      all: ['listitem']
    },
    nameFrom: ['author'],
    context: null,
    implicit: ['ol', 'ul', 'dl'],
    unsupported: false
  },
  listbox: {
    type: 'composite',
    attributes: {
      allowed: [
        'aria-activedescendant',
        'aria-multiselectable',
        'aria-readonly',
        'aria-required',
        'aria-expanded',
        'aria-orientation',
        'aria-errormessage'
      ]
    },
    owned: {
      all: ['option']
    },
    nameFrom: ['author'],
    context: null,
    implicit: ['select'],
    unsupported: false,
    allowedElements: ['ol', 'ul']
  },
  listitem: {
    type: 'structure',
    attributes: {
      allowed: [
        'aria-level',
        'aria-posinset',
        'aria-setsize',
        'aria-expanded',
        'aria-errormessage'
      ]
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: ['list'],
    implicit: ['li', 'dt'],
    unsupported: false
  },
  log: {
    type: 'widget',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  main: {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: ['main'],
    unsupported: false,
    allowedElements: ['article', 'section']
  },
  marquee: {
    type: 'widget',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  math: {
    type: 'structure',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: ['math'],
    unsupported: false
  },
  menu: {
    type: 'composite',
    attributes: {
      allowed: [
        'aria-activedescendant',
        'aria-expanded',
        'aria-orientation',
        'aria-errormessage'
      ]
    },
    owned: {
      one: ['menuitem', 'menuitemradio', 'menuitemcheckbox']
    },
    nameFrom: ['author'],
    context: null,
    implicit: ['menu[type="context"]'],
    unsupported: false,
    allowedElements: ['ol', 'ul']
  },
  menubar: {
    type: 'composite',
    attributes: {
      allowed: [
        'aria-activedescendant',
        'aria-expanded',
        'aria-orientation',
        'aria-errormessage'
      ]
    },
    owned: {
      one: ['menuitem', 'menuitemradio', 'menuitemcheckbox']
    },
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['ol', 'ul']
  },
  menuitem: {
    type: 'widget',
    attributes: {
      allowed: [
        'aria-posinset',
        'aria-setsize',
        'aria-expanded',
        'aria-errormessage'
      ]
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: ['menu', 'menubar'],
    implicit: ['menuitem[type="command"]'],
    unsupported: false,
    allowedElements: [
      'button',
      'li',
      {
        nodeName: 'iput',
        properties: {
          type: ['image', 'button']
        }
      },
      {
        nodeName: 'a',
        attributes: {
          href: isNotNull
        }
      }
    ]
  },
  menuitemcheckbox: {
    type: 'widget',
    attributes: {
      allowed: [
        'aria-checked',
        'aria-posinset',
        'aria-setsize',
        'aria-errormessage'
      ]
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: ['menu', 'menubar'],
    implicit: ['menuitem[type="checkbox"]'],
    unsupported: false,
    allowedElements: [
      {
        nodeName: ['button', 'li']
      },
      {
        nodeName: 'input',
        properties: {
          type: ['checkbox', 'image', 'button']
        }
      },
      {
        nodeName: 'a',
        attributes: {
          href: isNotNull
        }
      }
    ]
  },
  menuitemradio: {
    type: 'widget',
    attributes: {
      allowed: [
        'aria-checked',
        'aria-selected',
        'aria-posinset',
        'aria-setsize',
        'aria-errormessage'
      ]
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: ['menu', 'menubar'],
    implicit: ['menuitem[type="radio"]'],
    unsupported: false,
    allowedElements: [
      {
        nodeName: ['button', 'li']
      },
      {
        nodeName: 'input',
        properties: {
          type: ['image', 'button', 'radio']
        }
      },
      {
        nodeName: 'a',
        attributes: {
          href: isNotNull
        }
      }
    ]
  },
  navigation: {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: ['nav'],
    unsupported: false,
    allowedElements: ['section']
  },
  none: {
    type: 'structure',
    attributes: null,
    owned: null,
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: [
      {
        nodeName: [
          'article',
          'aside',
          'dl',
          'embed',
          'figcaption',
          'fieldset',
          'figure',
          'footer',
          'form',
          'h1',
          'h2',
          'h3',
          'h4',
          'h5',
          'h6',
          'header',
          'hr',
          'iframe',
          'li',
          'ol',
          'section',
          'ul'
        ]
      },
      {
        nodeName: 'img',
        attributes: {
          alt: isNotNull
        }
      }
    ]
  },
  note: {
    type: 'structure',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['aside']
  },
  option: {
    type: 'widget',
    attributes: {
      allowed: [
        'aria-selected',
        'aria-posinset',
        'aria-setsize',
        'aria-checked',
        'aria-errormessage'
      ]
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: ['listbox'],
    implicit: ['option'],
    unsupported: false,
    allowedElements: [
      {
        nodeName: ['button', 'li']
      },
      {
        nodeName: 'input',
        properties: {
          type: ['checkbox', 'button']
        }
      },
      {
        nodeName: 'a',
        attributes: {
          href: isNotNull
        }
      }
    ]
  },
  presentation: {
    type: 'structure',
    attributes: null,
    owned: null,
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: [
      {
        nodeName: [
          'article',
          'aside',
          'dl',
          'embed',
          'figcaption',
          'fieldset',
          'figure',
          'footer',
          'form',
          'h1',
          'h2',
          'h3',
          'h4',
          'h5',
          'h6',
          'header',
          'hr',
          'iframe',
          'li',
          'ol',
          'section',
          'ul'
        ]
      },
      {
        nodeName: 'img',
        attributes: {
          alt: isNotNull
        }
      }
    ]
  },
  progressbar: {
    type: 'widget',
    attributes: {
      allowed: [
        'aria-valuetext',
        'aria-valuenow',
        'aria-valuemax',
        'aria-valuemin',
        'aria-expanded',
        'aria-errormessage'
      ]
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: ['progress'],
    unsupported: false
  },
  radio: {
    type: 'widget',
    attributes: {
      allowed: [
        'aria-selected',
        'aria-posinset',
        'aria-setsize',
        'aria-required',
        'aria-errormessage',
        'aria-checked'
      ]
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: null,
    implicit: ['input[type="radio"]'],
    unsupported: false,
    allowedElements: [
      {
        nodeName: ['button', 'li']
      },
      {
        nodeName: 'input',
        properties: {
          type: ['image', 'button']
        }
      }
    ]
  },
  radiogroup: {
    type: 'composite',
    attributes: {
      allowed: [
        'aria-activedescendant',
        'aria-required',
        'aria-expanded',
        'aria-readonly',
        'aria-errormessage',
        'aria-orientation'
      ]
    },
    owned: {
      all: ['radio']
    },
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: {
      nodeName: ['ol', 'ul', 'fieldset']
    }
  },
  range: {
    nameFrom: ['author'],
    type: 'abstract',
    // @marcysutton, @wilco
    // - there is no unsupported here (noticed when resolving conflicts) from PR - https://github.com/dequelabs/axe-core/pull/1064
    // - https://github.com/dequelabs/axe-core/pull/1064/files#diff-ec67bb6113bfd9a900ee27ecef942f74R1229
    // - adding unsupported flag (false)
    unsupported: false
  },
  region: {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: [
      'section[aria-label]',
      'section[aria-labelledby]',
      'section[title]'
    ],
    unsupported: false,
    allowedElements: {
      nodeName: ['article', 'aside']
    }
  },
  roletype: {
    type: 'abstract',
    unsupported: false
  },
  row: {
    type: 'structure',
    attributes: {
      allowed: [
        'aria-activedescendant',
        'aria-colindex',
        'aria-expanded',
        'aria-level',
        'aria-selected',
        'aria-rowindex',
        'aria-errormessage'
      ]
    },
    owned: {
      one: ['cell', 'columnheader', 'rowheader', 'gridcell']
    },
    nameFrom: ['author', 'contents'],
    context: ['rowgroup', 'grid', 'treegrid', 'table'],
    implicit: ['tr'],
    unsupported: false
  },
  rowgroup: {
    type: 'structure',
    attributes: {
      allowed: ['aria-activedescendant', 'aria-expanded', 'aria-errormessage']
    },
    owned: {
      all: ['row']
    },
    nameFrom: ['author', 'contents'],
    context: ['grid', 'table', 'treegrid'],
    implicit: ['tbody', 'thead', 'tfoot'],
    unsupported: false
  },
  rowheader: {
    type: 'structure',
    attributes: {
      allowed: [
        'aria-colindex',
        'aria-colspan',
        'aria-expanded',
        'aria-rowindex',
        'aria-rowspan',
        'aria-required',
        'aria-readonly',
        'aria-selected',
        'aria-sort',
        'aria-errormessage'
      ]
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: ['row'],
    implicit: ['th'],
    unsupported: false
  },
  scrollbar: {
    type: 'widget',
    attributes: {
      required: ['aria-controls', 'aria-valuenow'],
      allowed: [
        'aria-valuetext',
        'aria-orientation',
        'aria-errormessage',
        'aria-valuemax',
        'aria-valuemin'
      ]
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    unsupported: false
  },
  search: {
    type: 'landmark',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: {
      nodeName: ['aside', 'form', 'section']
    }
  },
  searchbox: {
    type: 'widget',
    attributes: {
      allowed: [
        'aria-activedescendant',
        'aria-autocomplete',
        'aria-multiline',
        'aria-readonly',
        'aria-required',
        'aria-placeholder',
        'aria-errormessage'
      ]
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: ['input[type="search"]'],
    unsupported: false,
    allowedElements: {
      nodeName: 'input',
      properties: {
        type: 'text'
      }
    }
  },
  section: {
    nameFrom: ['author', 'contents'],
    type: 'abstract',
    unsupported: false
  },
  sectionhead: {
    nameFrom: ['author', 'contents'],
    type: 'abstract',
    unsupported: false
  },
  select: {
    nameFrom: ['author'],
    type: 'abstract',
    unsupported: false
  },
  separator: {
    type: 'structure',
    attributes: {
      allowed: [
        'aria-expanded',
        'aria-orientation',
        'aria-valuenow',
        'aria-valuemax',
        'aria-valuemin',
        'aria-valuetext',
        'aria-errormessage'
      ]
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: ['hr'],
    unsupported: false,
    allowedElements: ['li']
  },
  slider: {
    type: 'widget',
    attributes: {
      allowed: [
        'aria-valuetext',
        'aria-orientation',
        'aria-readonly',
        'aria-errormessage',
        'aria-valuemax',
        'aria-valuemin'
      ],
      required: ['aria-valuenow']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: ['input[type="range"]'],
    unsupported: false
  },
  spinbutton: {
    type: 'widget',
    attributes: {
      allowed: [
        'aria-valuetext',
        'aria-required',
        'aria-readonly',
        'aria-errormessage',
        'aria-valuemax',
        'aria-valuemin'
      ],
      required: ['aria-valuenow']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: ['input[type="number"]'],
    unsupported: false,
    allowedElements: {
      nodeName: 'input',
      properties: {
        type: ['text', 'tel']
      }
    }
  },
  status: {
    type: 'widget',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: ['output'],
    unsupported: false,
    allowedElements: ['section']
  },
  structure: {
    type: 'abstract',
    unsupported: false
  },
  switch: {
    type: 'widget',
    attributes: {
      allowed: ['aria-errormessage'],
      required: ['aria-checked']
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: null,
    unsupported: false,
    allowedElements: [
      'button',
      {
        nodeName: 'input',
        properties: {
          type: ['checkbox', 'image', 'button']
        }
      },
      {
        nodeName: 'a',
        attributes: {
          href: isNotNull
        }
      }
    ]
  },
  tab: {
    type: 'widget',
    attributes: {
      allowed: [
        'aria-selected',
        'aria-expanded',
        'aria-setsize',
        'aria-posinset',
        'aria-errormessage'
      ]
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: ['tablist'],
    unsupported: false,
    allowedElements: [
      {
        nodeName: ['button', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li']
      },
      {
        nodeName: 'input',
        properties: {
          type: 'button'
        }
      },
      {
        nodeName: 'a',
        attributes: {
          href: isNotNull
        }
      }
    ]
  },
  table: {
    type: 'structure',
    attributes: {
      allowed: ['aria-colcount', 'aria-rowcount', 'aria-errormessage']
    },
    owned: {
      one: ['rowgroup', 'row']
    },
    nameFrom: ['author', 'contents'],
    context: null,
    implicit: ['table'],
    unsupported: false
  },
  tablist: {
    type: 'composite',
    attributes: {
      allowed: [
        'aria-activedescendant',
        'aria-expanded',
        'aria-level',
        'aria-multiselectable',
        'aria-orientation',
        'aria-errormessage'
      ]
    },
    owned: {
      all: ['tab']
    },
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['ol', 'ul']
  },
  tabpanel: {
    type: 'widget',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['section']
  },
  term: {
    type: 'structure',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: null,
    implicit: ['dt'],
    unsupported: false
  },
  textbox: {
    type: 'widget',
    attributes: {
      allowed: [
        'aria-activedescendant',
        'aria-autocomplete',
        'aria-multiline',
        'aria-readonly',
        'aria-required',
        'aria-placeholder',
        'aria-errormessage'
      ]
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: [
      'input[type="text"]',
      'input[type="email"]',
      'input[type="password"]',
      'input[type="tel"]',
      'input[type="url"]',
      'input:not([type])',
      'textarea'
    ],
    unsupported: false
  },
  timer: {
    type: 'widget',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    unsupported: false
  },
  toolbar: {
    type: 'structure',
    attributes: {
      allowed: [
        'aria-activedescendant',
        'aria-expanded',
        'aria-orientation',
        'aria-errormessage'
      ]
    },
    owned: null,
    nameFrom: ['author'],
    context: null,
    implicit: ['menu[type="toolbar"]'],
    unsupported: false,
    allowedElements: ['ol', 'ul']
  },
  tooltip: {
    type: 'structure',
    attributes: {
      allowed: ['aria-expanded', 'aria-errormessage']
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: null,
    unsupported: false
  },
  tree: {
    type: 'composite',
    attributes: {
      allowed: [
        'aria-activedescendant',
        'aria-multiselectable',
        'aria-required',
        'aria-expanded',
        'aria-orientation',
        'aria-errormessage'
      ]
    },
    owned: {
      all: ['treeitem']
    },
    nameFrom: ['author'],
    context: null,
    unsupported: false,
    allowedElements: ['ol', 'ul']
  },
  treegrid: {
    type: 'composite',
    attributes: {
      allowed: [
        'aria-activedescendant',
        'aria-colcount',
        'aria-expanded',
        'aria-level',
        'aria-multiselectable',
        'aria-readonly',
        'aria-required',
        'aria-rowcount',
        'aria-orientation',
        'aria-errormessage'
      ]
    },
    owned: {
      one: ['rowgroup', 'row']
    },
    nameFrom: ['author'],
    context: null,
    unsupported: false
  },
  treeitem: {
    type: 'widget',
    attributes: {
      allowed: [
        'aria-checked',
        'aria-selected',
        'aria-expanded',
        'aria-level',
        'aria-posinset',
        'aria-setsize',
        'aria-errormessage'
      ]
    },
    owned: null,
    nameFrom: ['author', 'contents'],
    context: ['group', 'tree'],
    unsupported: false,
    allowedElements: [
      'li',
      {
        nodeName: 'a',
        attributes: {
          href: isNotNull
        }
      }
    ]
  },
  widget: {
    type: 'abstract',
    unsupported: false
  },
  window: {
    nameFrom: ['author'],
    type: 'abstract',
    unsupported: false
  }
};

lookupTable.implicitHtmlRole = implicitHtmlRoles;

// Source: https://www.w3.org/TR/html-aria/
lookupTable.elementsAllowedNoRole = [
  {
    // Plain HTML nodes
    nodeName: [
      'base',
      'body',
      'caption',
      'col',
      'colgroup',
      'datalist',
      'dd',
      'details',
      'dt',
      'head',
      'html',
      'keygen',
      'label',
      'legend',
      'main',
      'map',
      'math',
      'meta',
      'meter',
      'noscript',
      'optgroup',
      'param',
      'picture',
      'progress',
      'script',
      'source',
      'style',
      'template',
      'textarea',
      'title',
      'track'
    ]
  },
  {
    nodeName: 'area',
    attributes: {
      href: isNotNull
    }
  },
  {
    nodeName: 'input',
    properties: {
      type: [
        'color',
        'data',
        'datatime',
        'file',
        'hidden',
        'month',
        'number',
        'password',
        'range',
        'reset',
        'submit',
        'time',
        'week'
      ]
    }
  },
  {
    nodeName: 'link',
    attributes: {
      href: isNotNull
    }
  },
  {
    nodeName: 'menu',
    attributes: {
      type: 'context'
    }
  },
  {
    nodeName: 'menuitem',
    attributes: {
      type: ['command', 'checkbox', 'radio']
    }
  },
  {
    nodeName: 'select',
    condition: vNode => {
      if (!(vNode instanceof axe.AbstractVirtualNode)) {
        vNode = axe.utils.getNodeFromTree(vNode);
      }

      return Number(vNode.attr('size')) > 1;
    },
    properties: {
      multiple: true
    }
  },
  // svg elements (below)
  {
    nodeName: [
      'clippath',
      'cursor',
      'defs',
      'desc',
      'feblend',
      'fecolormatrix',
      'fecomponenttransfer',
      'fecomposite',
      'feconvolvematrix',
      'fediffuselighting',
      'fedisplacementmap',
      'fedistantlight',
      'fedropshadow',
      'feflood',
      'fefunca',
      'fefuncb',
      'fefuncg',
      'fefuncr',
      'fegaussianblur',
      'feimage',
      'femerge',
      'femergenode',
      'femorphology',
      'feoffset',
      'fepointlight',
      'fespecularlighting',
      'fespotlight',
      'fetile',
      'feturbulence',
      'filter',
      'hatch',
      'hatchpath',
      'lineargradient',
      'marker',
      'mask',
      'meshgradient',
      'meshpatch',
      'meshrow',
      'metadata',
      'mpath',
      'pattern',
      'radialgradient',
      'solidcolor',
      'stop',
      'switch',
      'view'
    ]
  }
];

// Source: https://www.w3.org/TR/html-aria/
lookupTable.elementsAllowedAnyRole = [
  {
    nodeName: 'a',
    attributes: {
      href: isNull
    }
  },
  {
    nodeName: 'img',
    attributes: {
      alt: isNull
    }
  },
  {
    nodeName: [
      'abbr',
      'address',
      'canvas',
      'div',
      'p',
      'pre',
      'blockquote',
      'ins',
      'del',
      'output',
      'span',
      'table',
      'tbody',
      'thead',
      'tfoot',
      'td',
      'em',
      'strong',
      'small',
      's',
      'cite',
      'q',
      'dfn',
      'abbr',
      'time',
      'code',
      'var',
      'samp',
      'kbd',
      'sub',
      'sup',
      'i',
      'b',
      'u',
      'mark',
      'ruby',
      'rt',
      'rp',
      'bdi',
      'bdo',
      'br',
      'wbr',
      'th',
      'tr'
    ]
  }
];

lookupTable.evaluateRoleForElement = {
  A: ({ node, out }) => {
    if (node.namespaceURI === 'http://www.w3.org/2000/svg') {
      return true;
    }
    if (node.href.length) {
      return out;
    }
    return true;
  },
  AREA: ({ node }) => !node.href,
  BUTTON: ({ node, role, out }) => {
    if (node.getAttribute('type') === 'menu') {
      return role === 'menuitem';
    }
    return out;
  },
  IMG: ({ node, role, out }) => {
    switch (node.alt) {
      case null:
        return out;
      case '':
        return role === 'presentation' || role === 'none';
      default:
        return role !== 'presentation' && role !== 'none';
    }
  },
  INPUT: ({ node, role, out }) => {
    switch (node.type) {
      case 'button':
      case 'image':
        return out;
      case 'checkbox':
        if (role === 'button' && node.hasAttribute('aria-pressed')) {
          return true;
        }
        return out;
      case 'radio':
        return role === 'menuitemradio';
      case 'text':
        return (
          role === 'combobox' || role === 'searchbox' || role === 'spinbutton'
        );
      case 'tel':
        return role === 'combobox' || role === 'spinbutton';
      case 'url':
      case 'search':
      case 'email':
        return role === 'combobox';
      default:
        return false;
    }
  },
  LI: ({ node, out }) => {
    const hasImplicitListitemRole = axe.utils.matchesSelector(
      node,
      'ol li, ul li'
    );
    if (hasImplicitListitemRole) {
      return out;
    }
    return true;
  },
  MENU: ({ node }) => {
    if (node.getAttribute('type') === 'context') {
      return false;
    }
    return true;
  },
  OPTION: ({ node }) => {
    const withinOptionList = axe.utils.matchesSelector(
      node,
      'select > option, datalist > option, optgroup > option'
    );
    return !withinOptionList;
  },
  SELECT: ({ node, role }) =>
    !node.multiple && node.size <= 1 && role === 'menu',
  SVG: ({ node, out }) => {
    // if in svg context it all roles may be used
    if (
      node.parentNode &&
      node.parentNode.namespaceURI === 'http://www.w3.org/2000/svg'
    ) {
      return true;
    }
    return out;
  }
};

/**
 * Note:
 * 	Usage of `rolesOfType` is deprecated within the source code.
 * 	Leaving this here for now, to keep support for custom rules.
 */
lookupTable.rolesOfType = {
  widget: [
    'button',
    'checkbox',
    'dialog',
    'gridcell',
    'link',
    'log',
    'marquee',
    'menuitem',
    'menuitemcheckbox',
    'menuitemradio',
    'option',
    'progressbar',
    'radio',
    'scrollbar',
    'searchbox',
    'slider',
    'spinbutton',
    'status',
    'switch',
    'tab',
    'tabpanel',
    'textbox',
    'timer',
    'tooltip',
    'tree',
    'treeitem'
  ]
};

export default lookupTable;
