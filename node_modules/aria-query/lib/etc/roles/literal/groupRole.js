"use strict";

var _Object$defineProperty = require("@babel/runtime-corejs3/core-js-stable/object/define-property");

_Object$defineProperty(exports, "__esModule", {
  value: true
});

exports.default = void 0;
var groupRole = {
  abstract: false,
  accessibleNameRequired: false,
  baseConcepts: [],
  childrenPresentational: false,
  nameFrom: ['author'],
  prohibitedProps: [],
  props: {
    'aria-activedescendant': null,
    'aria-disabled': null
  },
  relatedConcepts: [{
    concept: {
      name: 'details'
    },
    module: 'HTML'
  }, {
    concept: {
      name: 'fieldset'
    },
    module: 'HTML'
  }, {
    concept: {
      name: 'optgroup'
    },
    module: 'HTML'
  }],
  requireContextRole: [],
  requiredContextRole: [],
  requiredOwnedElements: [],
  requiredProps: {},
  superClass: [['roletype', 'structure', 'section']]
};
var _default = groupRole;
exports.default = _default;