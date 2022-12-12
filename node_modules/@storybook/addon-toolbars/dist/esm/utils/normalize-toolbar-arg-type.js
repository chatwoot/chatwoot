import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.array.map.js";
var defaultItemValues = {
  type: 'item',
  value: ''
};
export var normalizeArgType = function normalizeArgType(key, argType) {
  return Object.assign({}, argType, {
    name: argType.name || key,
    description: argType.description || key,
    toolbar: Object.assign({}, argType.toolbar, {
      items: argType.toolbar.items.map(function (_item) {
        var item = typeof _item === 'string' ? {
          value: _item,
          title: _item
        } : _item; // Cater for the special type "reset" which will reset value and also icon
        // of toolbar button if any icon was present on toolbar to begin with

        if (item.type === 'reset' && argType.toolbar.icon) {
          item.icon = argType.toolbar.icon;
          item.hideIcon = true;
        }

        return Object.assign({}, defaultItemValues, item);
      })
    })
  });
};