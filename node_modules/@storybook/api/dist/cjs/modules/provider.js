"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.init = void 0;

var init = function init(_ref) {
  var provider = _ref.provider,
      fullAPI = _ref.fullAPI;
  return {
    api: provider.renderPreview ? {
      renderPreview: provider.renderPreview
    } : {},
    init: function init() {
      provider.handleAPI(fullAPI);
    }
  };
};

exports.init = init;