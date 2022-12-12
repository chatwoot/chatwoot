import "core-js/modules/es.array.find.js";
import "core-js/modules/es.object.to-string.js";
export var getSelectedItem = function getSelectedItem(_ref) {
  var currentValue = _ref.currentValue,
      items = _ref.items;
  var selectedItem = currentValue != null && items.find(function (item) {
    return item.value === currentValue;
  });
  return selectedItem;
};
export var getSelectedIcon = function getSelectedIcon(_ref2) {
  var currentValue = _ref2.currentValue,
      items = _ref2.items;
  var selectedItem = getSelectedItem({
    currentValue: currentValue,
    items: items
  });
  return selectedItem === null || selectedItem === void 0 ? void 0 : selectedItem.icon;
};
export var getSelectedTitle = function getSelectedTitle(_ref3) {
  var currentValue = _ref3.currentValue,
      items = _ref3.items;
  var selectedItem = getSelectedItem({
    currentValue: currentValue,
    items: items
  });
  return selectedItem === null || selectedItem === void 0 ? void 0 : selectedItem.title;
};