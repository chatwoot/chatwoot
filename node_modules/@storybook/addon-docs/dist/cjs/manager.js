"use strict";

require("core-js/modules/es.array.concat.js");

var _addons = require("@storybook/addons");

var _shared = require("./shared");

_addons.addons.register(_shared.ADDON_ID, function () {
  _addons.addons.add(_shared.PANEL_ID, {
    type: _addons.types.TAB,
    title: 'Docs',
    route: function route(_ref) {
      var storyId = _ref.storyId,
          refId = _ref.refId;
      return refId ? "/docs/".concat(refId, "_").concat(storyId) : "/docs/".concat(storyId);
    },
    match: function match(_ref2) {
      var viewMode = _ref2.viewMode;
      return viewMode === 'docs';
    },
    render: function render() {
      return null;
    }
  });
});