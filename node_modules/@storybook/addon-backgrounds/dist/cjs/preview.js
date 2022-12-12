"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.parameters = exports.decorators = void 0;

var _withBackground = require("./decorators/withBackground");

var _withGrid = require("./decorators/withGrid");

var decorators = [_withGrid.withGrid, _withBackground.withBackground];
exports.decorators = decorators;
var parameters = {
  backgrounds: {
    grid: {
      cellSize: 20,
      opacity: 0.5,
      cellAmount: 5
    },
    values: [{
      name: 'light',
      value: '#F8F8F8'
    }, {
      name: 'dark',
      value: '#333333'
    }]
  }
};
exports.parameters = parameters;