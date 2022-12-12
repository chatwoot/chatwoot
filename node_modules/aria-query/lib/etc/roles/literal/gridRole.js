"use strict";

var _Object$defineProperty = require("@babel/runtime-corejs3/core-js-stable/object/define-property");

_Object$defineProperty(exports, "__esModule", {
  value: true
});

exports.default = void 0;
var gridRole = {
  abstract: false,
  accessibleNameRequired: true,
  baseConcepts: [],
  childrenPresentational: false,
  nameFrom: ['author'],
  prohibitedProps: [],
  props: {
    'aria-multiselectable': null,
    'aria-readonly': null
  },
  relatedConcepts: [{
    concept: {
      attributes: [{
        name: 'role',
        value: 'grid'
      }],
      name: 'table'
    },
    module: 'HTML'
  }],
  requireContextRole: [],
  requiredContextRole: [],
  requiredOwnedElements: [['row'], ['row', 'rowgroup']],
  requiredProps: {},
  superClass: [['roletype', 'widget', 'composite'], ['roletype', 'structure', 'section', 'table']]
};
var _default = gridRole;
exports.default = _default;