// Source https://www.w3.org/TR/dpub-aria-1.0/
const dpubRoles = {
  'doc-abstract': {
    type: 'section',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['section']
  },
  'doc-acknowledgments': {
    type: 'landmark',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['landmark']
  },
  'doc-afterword': {
    type: 'landmark',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['landmark']
  },
  'doc-appendix': {
    type: 'landmark',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['landmark']
  },
  'doc-backlink': {
    type: 'link',
    allowedAttrs: ['aria-expanded'],
    nameFromContent: true,
    superclassRole: ['link']
  },
  'doc-biblioentry': {
    type: 'listitem',
    requiredContext: ['doc-bibliography'],
    allowedAttrs: [
      'aria-expanded',
      'aria-level',
      'aria-posinset',
      'aria-setsize'
    ],
    superclassRole: ['listitem']
  },
  'doc-bibliography': {
    type: 'landmark',
    requiredOwned: ['doc-biblioentry'],
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['landmark']
  },
  'doc-biblioref': {
    type: 'link',
    allowedAttrs: ['aria-expanded'],
    nameFromContent: true,
    superclassRole: ['link']
  },
  'doc-chapter': {
    type: 'landmark',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['landmark']
  },
  'doc-colophon': {
    type: 'section',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['section']
  },
  'doc-conclusion': {
    type: 'landmark',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['landmark']
  },
  'doc-cover': {
    type: 'img',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['img']
  },
  'doc-credit': {
    type: 'section',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['section']
  },
  'doc-credits': {
    type: 'landmark',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['landmark']
  },
  'doc-dedication': {
    type: 'section',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['section']
  },
  'doc-endnote': {
    type: 'listitem',
    requiredContext: ['doc-endnotes'],
    allowedAttrs: [
      'aria-expanded',
      'aria-level',
      'aria-posinset',
      'aria-setsize'
    ],
    superclassRole: ['listitem']
  },
  'doc-endnotes': {
    type: 'landmark',
    requiredOwned: ['doc-endnote'],
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['landmark']
  },
  'doc-epigraph': {
    type: 'section',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['section']
  },
  'doc-epilogue': {
    type: 'landmark',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['landmark']
  },
  'doc-errata': {
    type: 'landmark',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['landmark']
  },
  'doc-example': {
    type: 'section',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['section']
  },
  'doc-footnote': {
    type: 'section',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['section']
  },
  'doc-foreword': {
    type: 'landmark',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['landmark']
  },
  'doc-glossary': {
    type: 'landmark',
    requiredOwned: ['definition', 'term'],
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['landmark']
  },
  'doc-glossref': {
    type: 'link',
    allowedAttrs: ['aria-expanded'],
    nameFromContent: true,
    superclassRole: ['link']
  },
  'doc-index': {
    type: 'navigation',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['navigation']
  },
  'doc-introduction': {
    type: 'landmark',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['landmark']
  },
  'doc-noteref': {
    type: 'link',
    allowedAttrs: ['aria-expanded'],
    nameFromContent: true,
    superclassRole: ['link']
  },
  'doc-notice': {
    type: 'note',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['note']
  },
  'doc-pagebreak': {
    type: 'separator',
    allowedAttrs: ['aria-expanded', 'aria-orientation'],
    superclassRole: ['separator'],
    childrenPresentational: true
  },
  'doc-pagelist': {
    type: 'navigation',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['navigation']
  },
  'doc-part': {
    type: 'landmark',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['landmark']
  },
  'doc-preface': {
    type: 'landmark',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['landmark']
  },
  'doc-prologue': {
    type: 'landmark',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['landmark']
  },
  'doc-pullquote': {
    type: 'none',
    superclassRole: ['none']
  },
  'doc-qna': {
    type: 'section',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['section']
  },
  'doc-subtitle': {
    type: 'sectionhead',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['sectionhead']
  },
  'doc-tip': {
    type: 'note',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['note']
  },
  'doc-toc': {
    type: 'navigation',
    allowedAttrs: ['aria-expanded'],
    superclassRole: ['navigation']
  }
};

export default dpubRoles;
