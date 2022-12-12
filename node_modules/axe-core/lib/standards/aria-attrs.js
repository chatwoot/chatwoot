// Source: https://www.w3.org/TR/wai-aria-1.1/#states_and_properties
const ariaAttrs = {
  'aria-activedescendant': {
    type: 'idref',
    allowEmpty: true
  },
  'aria-atomic': {
    type: 'boolean',
    global: true
  },
  'aria-autocomplete': {
    type: 'nmtoken',
    values: ['inline', 'list', 'both', 'none']
  },
  'aria-busy': {
    type: 'boolean',
    global: true
  },
  'aria-checked': {
    type: 'nmtoken',
    values: ['false', 'mixed', 'true', 'undefined']
  },
  'aria-colcount': {
    type: 'int',
    minValue: -1
  },
  'aria-colindex': {
    type: 'int',
    minValue: 1
  },
  'aria-colspan': {
    type: 'int',
    minValue: 1
  },
  'aria-controls': {
    type: 'idrefs',
    allowEmpty: true,
    global: true
  },
  'aria-current': {
    type: 'nmtoken',
    allowEmpty: true,
    values: ['page', 'step', 'location', 'date', 'time', 'true', 'false'],
    global: true
  },
  'aria-describedby': {
    type: 'idrefs',
    allowEmpty: true,
    global: true
  },
  'aria-details': {
    type: 'idref',
    allowEmpty: true,
    global: true
  },
  'aria-disabled': {
    type: 'boolean',
    global: true
  },
  'aria-dropeffect': {
    type: 'nmtokens',
    values: ['copy', 'execute', 'link', 'move', 'none', 'popup'],
    global: true
  },
  'aria-errormessage': {
    type: 'idref',
    allowEmpty: true,
    global: true
  },
  'aria-expanded': {
    type: 'nmtoken',
    values: ['true', 'false', 'undefined']
  },
  'aria-flowto': {
    type: 'idrefs',
    allowEmpty: true,
    global: true
  },
  'aria-grabbed': {
    type: 'nmtoken',
    values: ['true', 'false', 'undefined'],
    global: true
  },
  'aria-haspopup': {
    type: 'nmtoken',
    allowEmpty: true,
    values: ['true', 'false', 'menu', 'listbox', 'tree', 'grid', 'dialog'],
    global: true
  },
  'aria-hidden': {
    type: 'nmtoken',
    values: ['true', 'false', 'undefined'],
    global: true
  },
  'aria-invalid': {
    type: 'nmtoken',
    allowEmpty: true,
    values: ['grammar', 'false', 'spelling', 'true'],
    global: true
  },
  'aria-keyshortcuts': {
    type: 'string',
    allowEmpty: true,
    global: true
  },
  'aria-label': {
    type: 'string',
    allowEmpty: true,
    global: true
  },
  'aria-labelledby': {
    type: 'idrefs',
    allowEmpty: true,
    global: true
  },
  'aria-level': {
    type: 'int',
    minValue: 1
  },
  'aria-live': {
    type: 'nmtoken',
    values: ['assertive', 'off', 'polite'],
    global: true
  },
  'aria-modal': {
    type: 'boolean'
  },
  'aria-multiline': {
    type: 'boolean'
  },
  'aria-multiselectable': {
    type: 'boolean'
  },
  'aria-orientation': {
    type: 'nmtoken',
    values: ['horizontal', 'undefined', 'vertical']
  },
  'aria-owns': {
    type: 'idrefs',
    allowEmpty: true,
    global: true
  },
  'aria-placeholder': {
    type: 'string',
    allowEmpty: true
  },
  'aria-posinset': {
    type: 'int',
    minValue: 1
  },
  'aria-pressed': {
    type: 'nmtoken',
    values: ['false', 'mixed', 'true', 'undefined']
  },
  'aria-readonly': {
    type: 'boolean'
  },
  'aria-relevant': {
    type: 'nmtokens',
    values: ['additions', 'all', 'removals', 'text'],
    global: true
  },
  'aria-required': {
    type: 'boolean'
  },
  'aria-roledescription': {
    type: 'string',
    allowEmpty: true,
    global: true
  },
  'aria-rowcount': {
    type: 'int',
    minValue: -1
  },
  'aria-rowindex': {
    type: 'int',
    minValue: 1
  },
  'aria-rowspan': {
    type: 'int',
    minValue: 0
  },
  'aria-selected': {
    type: 'nmtoken',
    values: ['false', 'true', 'undefined']
  },
  'aria-setsize': {
    type: 'int',
    minValue: -1
  },
  'aria-sort': {
    type: 'nmtoken',
    values: ['ascending', 'descending', 'none', 'other']
  },
  'aria-valuemax': {
    type: 'decimal'
  },
  'aria-valuemin': {
    type: 'decimal'
  },
  'aria-valuenow': {
    type: 'decimal'
  },
  'aria-valuetext': {
    type: 'string'
  }
};

export default ariaAttrs;
