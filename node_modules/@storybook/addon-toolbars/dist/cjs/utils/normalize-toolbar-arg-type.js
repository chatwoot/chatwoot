"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.normalizeArgType = void 0;

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.array.map.js");

var defaultItemValues = {
  type: 'item',
  value: ''
};

var normalizeArgType = function normalizeArgType(key, argType) {
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

exports.normalizeArgType = normalizeArgType;