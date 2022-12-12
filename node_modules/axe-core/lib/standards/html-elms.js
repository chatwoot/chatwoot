// Source: https://www.w3.org/TR/html-aria/#allowed-aria-roles-states-and-properties
// Source: https://www.w3.org/TR/html-aam-1.0/#html-element-role-mappings
// Source https://html.spec.whatwg.org/multipage/dom.html#content-models
// Source https://dom.spec.whatwg.org/#dom-element-attachshadow
const htmlElms = {
  a: {
    // Note: variants work by matching the node against the
    // `matches` attribute. if the variant matches AND has the
    // desired property (contentTypes, etc.) then we use it,
    // otherwise we move on to the next matching variant
    variant: {
      href: {
        matches: '[href]',
        contentTypes: ['interactive', 'phrasing', 'flow'],
        allowedRoles: [
          'button',
          'checkbox',
          'menuitem',
          'menuitemcheckbox',
          'menuitemradio',
          'option',
          'radio',
          'switch',
          'tab',
          'treeitem',
          'doc-backlink',
          'doc-biblioref',
          'doc-glossref',
          'doc-noteref'
        ],
        namingMethods: ['subtreeText']
      },
      // Note: the default variant is a special variant and is
      // used as the last match if none of the other variants
      // match or have the desired attribute
      default: {
        contentTypes: ['phrasing', 'flow'],
        allowedRoles: true
      }
    }
  },
  abbr: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  addres: {
    contentTypes: ['flow'],
    allowedRoles: true
  },
  area: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: false,
    namingMethods: ['altText']
  },
  article: {
    contentTypes: ['sectioning', 'flow'],
    allowedRoles: [
      'feed',
      'presentation',
      'none',
      'document',
      'application',
      'main',
      'region'
    ],
    shadowRoot: true
  },
  aside: {
    contentTypes: ['sectioning', 'flow'],
    allowedRoles: [
      'feed',
      'note',
      'presentation',
      'none',
      'region',
      'search',
      'doc-dedication',
      'doc-example',
      'doc-footnote',
      'doc-pullquote',
      'doc-tip'
    ]
  },
  audio: {
    variant: {
      controls: {
        matches: '[controls]',
        contentTypes: ['interactive', 'embedded', 'phrasing', 'flow']
      },
      default: {
        contentTypes: ['embedded', 'phrasing', 'flow']
      }
    },
    // Note: if the property applies regardless of variants it is
    // placed at the top level instead of the default variant
    allowedRoles: ['application']
  },
  b: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: false
  },
  base: {
    allowedRoles: false,
    noAriaAttrs: true
  },
  bdi: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  bdo: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  blockquote: {
    contentTypes: ['flow'],
    allowedRoles: true,
    shadowRoot: true
  },
  body: {
    allowedRoles: false,
    shadowRoot: true
  },
  br: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: ['presentation', 'none'],
    namingMethods: ['titleText', 'singleSpace']
  },
  button: {
    contentTypes: ['interactive', 'phrasing', 'flow'],
    allowedRoles: [
      'checkbox',
      'link',
      'menuitem',
      'menuitemcheckbox',
      'menuitemradio',
      'option',
      'radio',
      'switch',
      'tab'
    ],
    // 5.4 button Element
    namingMethods: ['subtreeText']
  },
  canvas: {
    allowedRoles: true,
    contentTypes: ['embedded', 'phrasing', 'flow']
  },
  caption: {
    allowedRoles: false
  },
  cite: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  code: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  col: {
    allowedRoles: false,
    noAriaAttrs: true
  },
  colgroup: {
    allowedRoles: false,
    noAriaAttrs: true
  },
  data: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  datalist: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: false,
    implicitAttrs: {
      // Note: even though the value of aria-multiselectable is based
      // on the attributes, we don't currently need to know the
      // precise value. however, this allows us to make the attribute
      // future proof in case we ever do need to know it
      'aria-multiselectable': 'false'
    }
  },
  dd: {
    allowedRoles: false
  },
  del: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  dfn: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  details: {
    contentTypes: ['interactive', 'flow'],
    allowedRoles: false
  },
  dialog: {
    contentTypes: ['flow'],
    allowedRoles: ['alertdialog']
  },
  div: {
    contentTypes: ['flow'],
    allowedRoles: true,
    shadowRoot: true
  },
  dl: {
    contentTypes: ['flow'],
    allowedRoles: ['group', 'list', 'presentation', 'none']
  },
  dt: {
    allowedRoles: ['listitem']
  },
  em: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  embed: {
    contentTypes: ['interactive', 'embedded', 'phrasing', 'flow'],
    allowedRoles: ['application', 'document', 'img', 'presentation', 'none']
  },
  fieldset: {
    contentTypes: ['flow'],
    allowedRoles: ['none', 'presentation', 'radiogroup'],
    // 5.5 fieldset and legend Elements
    namingMethods: ['fieldsetLegendText']
  },
  figcaption: {
    allowedRoles: ['group', 'none', 'presentation']
  },
  figure: {
    contentTypes: ['flow'],
    // Note: technically you're allowed no role when a figcaption
    // descendant, but we can't match that so we'll go with any role
    allowedRoles: true,
    // 5.9 figure and figcaption Elements
    namingMethods: ['figureText', 'titleText']
  },
  footer: {
    contentTypes: ['flow'],
    allowedRoles: ['group', 'none', 'presentation', 'doc-footnote'],
    shadowRoot: true
  },
  form: {
    contentTypes: ['flow'],
    allowedRoles: ['search', 'none', 'presentation']
  },
  h1: {
    contentTypes: ['heading', 'flow'],
    allowedRoles: ['none', 'presentation', 'tab', 'doc-subtitle'],
    shadowRoot: true,
    implicitAttrs: {
      'aria-level': '1'
    }
  },
  h2: {
    contentTypes: ['heading', 'flow'],
    allowedRoles: ['none', 'presentation', 'tab', 'doc-subtitle'],
    shadowRoot: true,
    implicitAttrs: {
      'aria-level': '2'
    }
  },
  h3: {
    contentTypes: ['heading', 'flow'],
    allowedRoles: ['none', 'presentation', 'tab', 'doc-subtitle'],
    shadowRoot: true,
    implicitAttrs: {
      'aria-level': '3'
    }
  },
  h4: {
    contentTypes: ['heading', 'flow'],
    allowedRoles: ['none', 'presentation', 'tab', 'doc-subtitle'],
    shadowRoot: true,
    implicitAttrs: {
      'aria-level': '4'
    }
  },
  h5: {
    contentTypes: ['heading', 'flow'],
    allowedRoles: ['none', 'presentation', 'tab', 'doc-subtitle'],
    shadowRoot: true,
    implicitAttrs: {
      'aria-level': '5'
    }
  },
  h6: {
    contentTypes: ['heading', 'flow'],
    allowedRoles: ['none', 'presentation', 'tab', 'doc-subtitle'],
    shadowRoot: true,
    implicitAttrs: {
      'aria-level': '6'
    }
  },
  head: {
    allowedRoles: false,
    noAriaAttrs: true
  },
  header: {
    contentTypes: ['flow'],
    allowedRoles: ['group', 'none', 'presentation', 'doc-footnote'],
    shadowRoot: true
  },
  hgroup: {
    contentTypes: ['heading', 'flow'],
    allowedRoles: true
  },
  hr: {
    contentTypes: ['flow'],
    allowedRoles: ['none', 'presentation', 'doc-pagebreak'],
    namingMethods: ['titleText', 'singleSpace']
  },
  html: {
    allowedRoles: false,
    noAriaAttrs: true
  },
  i: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  iframe: {
    contentTypes: ['interactive', 'embedded', 'phrasing', 'flow'],
    allowedRoles: ['application', 'document', 'img', 'none', 'presentation']
  },
  img: {
    variant: {
      nonEmptyAlt: {
        matches: {
          attributes: {
            alt: '/.+/'
          }
        },
        allowedRoles: [
          'button',
          'checkbox',
          'link',
          'menuitem',
          'menuitemcheckbox',
          'menuitemradio',
          'option',
          'progressbar',
          'scrollbar',
          'separator',
          'slider',
          'switch',
          'tab',
          'treeitem',
          'doc-cover'
        ]
      },
      usemap: {
        matches: '[usemap]',
        contentTypes: ['interactive', 'embedded', 'phrasing', 'flow']
      },
      default: {
        // Note: allow role presentation and none on image with no
        // alt as a way to prevent axe from flagging the image as
        // needing an alt
        allowedRoles: ['presentation', 'none'],
        contentTypes: ['embedded', 'phrasing', 'flow']
      }
    },
    // 5.10 img Element
    namingMethods: ['altText']
  },
  input: {
    variant: {
      button: {
        matches: {
          properties: {
            type: 'button'
          }
        },
        allowedRoles: [
          'link',
          'menuitem',
          'menuitemcheckbox',
          'menuitemradio',
          'option',
          'radio',
          'switch',
          'tab'
        ]
      },
      // 5.2 input type="button", input type="submit" and input type="reset"
      buttonType: {
        matches: {
          properties: {
            type: ['button', 'submit', 'reset']
          }
        },
        namingMethods: ['valueText', 'titleText', 'buttonDefaultText']
      },
      checkboxPressed: {
        matches: {
          properties: {
            type: 'checkbox'
          },
          attributes: {
            'aria-pressed': '/.*/'
          }
        },
        allowedRoles: ['button', 'menuitemcheckbox', 'option', 'switch'],
        implicitAttrs: {
          'aria-checked': 'false'
        }
      },
      checkbox: {
        matches: {
          properties: {
            type: 'checkbox'
          },
          attributes: {
            'aria-pressed': null
          }
        },
        allowedRoles: ['menuitemcheckbox', 'option', 'switch'],
        implicitAttrs: {
          'aria-checked': 'false'
        }
      },
      noRoles: {
        matches: {
          properties: {
            // Note: types of url, search, tel, and email are listed
            // as not allowed roles however since they are text
            // types they should be allowed to have role=combobox
            type: [
              'color',
              'date',
              'datetime-local',
              'file',
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
        allowedRoles: false
      },
      hidden: {
        matches: {
          properties: {
            type: 'hidden'
          }
        },
        // Note: spec change (do not count as phrasing)
        contentTypes: ['flow'],
        allowedRoles: false,
        noAriaAttrs: true
      },
      image: {
        matches: {
          properties: {
            type: 'image'
          }
        },
        allowedRoles: [
          'link',
          'menuitem',
          'menuitemcheckbox',
          'menuitemradio',
          'radio',
          'switch'
        ],
        // 5.3 input type="image"
        namingMethods: [
          'altText',
          'valueText',
          'labelText',
          'titleText',
          'buttonDefaultText'
        ]
      },
      radio: {
        matches: {
          properties: {
            type: 'radio'
          }
        },
        allowedRoles: ['menuitemradio'],
        implicitAttrs: {
          'aria-checked': 'false'
        }
      },
      textWithList: {
        matches: {
          properties: {
            type: 'text'
          },
          attributes: {
            list: '/.*/'
          }
        },
        allowedRoles: false
      },
      default: {
        // Note: spec change (do not count as phrasing)
        contentTypes: ['interactive', 'flow'],
        allowedRoles: ['combobox', 'searchbox', 'spinbutton'],
        implicitAttrs: {
          'aria-valuenow': ''
        },
        // 5.1 input type="text", input type="password", input type="search", input type="tel", input type="url"
        // 5.7 Other Form Elements
        namingMethods: ['labelText', 'placeholderText']
      }
    }
  },
  ins: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  kbd: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  label: {
    contentTypes: ['interactive', 'phrasing', 'flow'],
    allowedRoles: false
  },
  legend: {
    allowedRoles: false
  },
  li: {
    allowedRoles: [
      'menuitem',
      'menuitemcheckbox',
      'menuitemradio',
      'option',
      'none',
      'presentation',
      'radio',
      'separator',
      'tab',
      'treeitem',
      'doc-biblioentry',
      'doc-endnote'
    ],
    implicitAttrs: {
      'aria-setsize': '1',
      'aria-posinset': '1'
    }
  },
  link: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: false,
    noAriaAttrs: true
  },
  main: {
    contentTypes: ['flow'],
    allowedRoles: false,
    shadowRoot: true
  },
  map: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: false,
    noAriaAttrs: true
  },
  math: {
    contentTypes: ['embedded', 'phrasing', 'flow'],
    allowedRoles: false
  },
  mark: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  menu: {
    contentTypes: ['flow'],
    allowedRoles: [
      'directory',
      'group',
      'listbox',
      'menu',
      'menubar',
      'none',
      'presentation',
      'radiogroup',
      'tablist',
      'toolbar',
      'tree'
    ]
  },
  meta: {
    variant: {
      itemprop: {
        matches: '[itemprop]',
        contentTypes: ['phrasing', 'flow']
      }
    },
    allowedRoles: false,
    noAriaAttrs: true
  },
  meter: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: false
  },
  nav: {
    contentTypes: ['sectioning', 'flow'],
    allowedRoles: ['doc-index', 'doc-pagelist', 'doc-toc'],
    shadowRoot: true
  },
  noscript: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: false,
    noAriaAttrs: true
  },
  object: {
    variant: {
      usemap: {
        matches: '[usemap]',
        contentTypes: ['interactive', 'embedded', 'phrasing', 'flow']
      },
      default: {
        contentTypes: ['embedded', 'phrasing', 'flow']
      }
    },
    allowedRoles: ['application', 'document', 'img']
  },
  ol: {
    contentTypes: ['flow'],
    allowedRoles: [
      'directory',
      'group',
      'listbox',
      'menu',
      'menubar',
      'none',
      'presentation',
      'radiogroup',
      'tablist',
      'toolbar',
      'tree'
    ]
  },
  optgroup: {
    allowedRoles: false
  },
  option: {
    allowedRoles: false,
    implicitAttrs: {
      'aria-selected': 'false'
    }
  },
  output: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true,
    // 5.6 output Element
    namingMethods: ['subtreeText']
  },
  p: {
    contentTypes: ['flow'],
    allowedRoles: true,
    shadowRoot: true
  },
  param: {
    allowedRoles: false,
    noAriaAttrs: true
  },
  picture: {
    contentTypes: ['embedded', 'phrasing', 'flow'],
    allowedRoles: false,
    noAriaAttrs: true
  },
  pre: {
    contentTypes: ['flow'],
    allowedRoles: true
  },
  progress: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true,
    implicitAttrs: {
      'aria-valuemax': '100',
      'aria-valuemin': '0',
      'aria-valuenow': '0'
    }
  },
  q: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  rp: {
    allowedRoles: true
  },
  rt: {
    allowedRoles: true
  },
  ruby: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  s: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  samp: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  script: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: false,
    noAriaAttrs: true
  },
  section: {
    contentTypes: ['sectioning', 'flow'],
    allowedRoles: [
      'alert',
      'alertdialog',
      'application',
      'banner',
      'complementary',
      'contentinfo',
      'dialog',
      'document',
      'feed',
      'log',
      'main',
      'marquee',
      'navigation',
      'none',
      'note',
      'presentation',
      'search',
      'status',
      'tabpanel',
      'doc-abstract',
      'doc-acknowledgments',
      'doc-afterword',
      'doc-appendix',
      'doc-bibliography',
      'doc-chapter',
      'doc-colophon',
      'doc-conclusion',
      'doc-credit',
      'doc-credits',
      'doc-dedication',
      'doc-endnotes',
      'doc-epigraph',
      'doc-epilogue',
      'doc-errata',
      'doc-example',
      'doc-foreword',
      'doc-glossary',
      'doc-index',
      'doc-introduction',
      'doc-notice',
      'doc-pagelist',
      'doc-part',
      'doc-preface',
      'doc-prologue',
      'doc-pullquote',
      'doc-qna',
      'doc-toc'
    ],
    shadowRoot: true
  },
  select: {
    variant: {
      combobox: {
        matches: {
          attributes: {
            multiple: null,
            size: [null, '1']
          }
        },
        allowedRoles: ['menu']
      },
      default: {
        allowedRoles: false
      }
    },
    contentTypes: ['interactive', 'phrasing', 'flow'],
    implicitAttrs: {
      'aria-valuenow': ''
    },
    // 5.7 Other form elements
    namingMethods: ['labelText']
  },
  slot: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: false,
    noAriaAttrs: true
  },
  small: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  source: {
    allowedRoles: false,
    noAriaAttrs: true
  },
  span: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true,
    shadowRoot: true
  },
  strong: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  style: {
    allowedRoles: false,
    noAriaAttrs: true
  },
  svg: {
    contentTypes: ['embedded', 'phrasing', 'flow'],
    allowedRoles: ['application', 'document', 'img'],
    namingMethods: ['svgTitleText']
  },
  sub: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  summary: {
    allowedRoles: false,
    // 5.8 summary Element
    namingMethods: ['subtreeText']
  },
  sup: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  table: {
    contentTypes: ['flow'],
    allowedRoles: true,
    // 5.11 table Element
    namingMethods: ['tableCaptionText', 'tableSummaryText']
  },
  tbody: {
    allowedRoles: true
  },
  template: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: false,
    noAriaAttrs: true
  },
  textarea: {
    contentTypes: ['interactive', 'phrasing', 'flow'],
    allowedRoles: false,
    implicitAttrs: {
      'aria-valuenow': '',
      'aria-multiline': 'true'
    },
    // 5.1 textarea
    namingMethods: ['labelText', 'placeholderText']
  },
  tfoot: {
    allowedRoles: true
  },
  thead: {
    allowedRoles: true
  },
  time: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  title: {
    allowedRoles: false,
    noAriaAttrs: true
  },
  td: {
    allowedRoles: true
  },
  th: {
    allowedRoles: true
  },
  tr: {
    allowedRoles: true
  },
  track: {
    allowedRoles: false,
    noAriaAttrs: true
  },
  u: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  ul: {
    contentTypes: ['flow'],
    allowedRoles: [
      'directory',
      'group',
      'listbox',
      'menu',
      'menubar',
      'none',
      'presentation',
      'radiogroup',
      'tablist',
      'toolbar',
      'tree'
    ]
  },
  var: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  },
  video: {
    variant: {
      controls: {
        matches: '[controls]',
        contentTypes: ['interactive', 'embedded', 'phrasing', 'flow']
      },
      default: {
        contentTypes: ['embedded', 'phrasing', 'flow']
      }
    },
    allowedRoles: ['application']
  },
  wbr: {
    contentTypes: ['phrasing', 'flow'],
    allowedRoles: true
  }
};

export default htmlElms;
