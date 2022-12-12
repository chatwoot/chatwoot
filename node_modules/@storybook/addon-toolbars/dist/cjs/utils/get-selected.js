"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getSelectedTitle = exports.getSelectedItem = exports.getSelectedIcon = void 0;

require("core-js/modules/es.array.find.js");

require("core-js/modules/es.object.to-string.js");

var getSelectedItem = function getSelectedItem(_ref) {
  var currentValue = _ref.currentValue,
      items = _ref.items;
  var selectedItem = currentValue != null && items.find(function (item) {
    return item.value === currentValue;
  });
  return selectedItem;
};

exports.getSelectedItem = getSelectedItem;

var getSelectedIcon = function getSelectedIcon(_ref2) {
  var currentValue = _ref2.currentValue,
      items = _ref2.items;
  var selectedItem = getSelectedItem({
    currentValue: currentValue,
    items: items
  });
  return selectedItem === null || selectedItem === void 0 ? void 0 : selectedItem.icon;
};

exports.getSelectedIcon = getSelectedIcon;

var getSelectedTitle = function getSelectedTitle(_ref3) {
  var currentValue = _ref3.currentValue,
      items = _ref3.items;
  var selectedItem = getSelectedItem({
    currentValue: currentValue,
    items: items
  });
  return selectedItem === null || selectedItem === void 0 ? void 0 : selectedItem.title;
};

exports.getSelectedTitle = getSelectedTitle;