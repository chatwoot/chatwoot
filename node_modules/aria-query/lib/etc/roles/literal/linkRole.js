"use strict";

var _Object$defineProperty = require("@babel/runtime-corejs3/core-js-stable/object/define-property");

_Object$defineProperty(exports, "__esModule", {
  value: true
});

exports.default = void 0;
var linkRole = {
  abstract: false,
  accessibleNameRequired: true,
  baseConcepts: [],
  childrenPresentational: false,
  nameFrom: ['author', 'contents'],
  prohibitedProps: [],
  props: {
    'aria-disabled': null,
    'aria-expanded': null
  },
  relatedConcepts: [{
    concept: {
      attributes: [{
        name: 'href'
      }],
      name: 'a'
    },
    module: 'HTML'
  }, {
    concept: {
      attributes: [{
        name: 'href'
      }],
      name: 'area'
    },
    module: 'HTML'
  }, {
    concept: {
      attributes: [{
        name: 'href'
      }],
      name: 'link'
    },
    module: 'HTML'
  }],
  requireContextRole: [],
  requiredContextRole: [],
  requiredOwnedElements: [],
  requiredProps: {},
  superClass: [['roletype', 'widget', 'command']]
};
var _default = linkRole;
exports.default = _default;