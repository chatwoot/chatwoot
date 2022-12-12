"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});

exports.default = function (calc, node, precision) {
  var str = stringify(node, precision);

  if (node.type === "MathExpression") {
    // if calc expression couldn't be resolved to a single value, re-wrap it as
    // a calc()
    str = calc + "(" + str + ")";
  }
  return str;
};

var _reducer = require("./reducer");

var order = {
  "*": 0,
  "/": 0,
  "+": 1,
  "-": 1
};

function round(value, prec) {
  if (prec !== false) {
    var precision = Math.pow(10, prec);
    return Math.round(value * precision) / precision;
  }
  return value;
}

function stringify(node, prec) {
  switch (node.type) {
    case "MathExpression":
      {
        var left = node.left,
            right = node.right,
            op = node.operator;

        var str = "";

        if (left.type === 'MathExpression' && order[op] < order[left.operator]) str += "(" + stringify(left, prec) + ")";else str += stringify(left, prec);

        str += " " + node.operator + " ";

        if (right.type === 'MathExpression' && order[op] < order[right.operator]) str += "(" + stringify(right, prec) + ")";else if (right.type === 'MathExpression' && op === "-" && ["+", "-"].includes(right.operator)) {
          // fix #52 : a-(b+c) = a-b-c
          right.operator = (0, _reducer.flip)(right.operator);
          str += stringify(right, prec);
        } else str += stringify(right, prec);

        return str;
      }
    case "Value":
      return round(node.value, prec);
    case 'CssVariable':
      return node.value;
    default:
      return round(node.value, prec) + node.unit;
  }
}

module.exports = exports["default"];