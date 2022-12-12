"use strict";

var _Object$defineProperty = require("@babel/runtime-corejs3/core-js-stable/object/define-property");

_Object$defineProperty(exports, "__esModule", {
  value: true
});

exports.default = void 0;
var rowgroupRole = {
  abstract: false,
  accessibleNameRequired: false,
  baseConcepts: [],
  childrenPresentational: false,
  nameFrom: ['author', 'contents'],
  prohibitedProps: [],
  props: {},
  relatedConcepts: [{
    concept: {
      name: 'tbody'
    },
    module: 'HTML'
  }, {
    concept: {
      name: 'tfoot'
    },
    module: 'HTML'
  }, {
    concept: {
      name: 'thead'
    },
    module: 'HTML'
  }],
  requireContextRole: ['grid', 'table', 'treegrid'],
  requiredContextRole: ['grid', 'table', 'treegrid'],
  requiredOwnedElements: [['row']],
  requiredProps: {},
  superClass: [['roletype', 'structure']]
};
var _default = rowgroupRole;
exports.default = _default;