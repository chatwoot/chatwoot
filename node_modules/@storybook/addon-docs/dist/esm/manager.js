import "core-js/modules/es.array.concat.js";
import { addons, types } from '@storybook/addons';
import { ADDON_ID, PANEL_ID } from './shared';
addons.register(ADDON_ID, function () {
  addons.add(PANEL_ID, {
    type: types.TAB,
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