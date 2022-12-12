// Source: https://www.w3.org/TR/graphics-aria-1.0/

const graphicsRoles = {
  'graphics-document': {
    type: 'structure',
    superclassRole: ['document'],
    accessibleNameRequired: true
  },
  'graphics-object': {
    type: 'structure',
    superclassRole: ['group'],
    nameFromContent: true
  },
  'graphics-symbol': {
    type: 'structure',
    superclassRole: ['img'],
    accessibleNameRequired: true,
    childrenPresentational: true
  }
};

export default graphicsRoles;
