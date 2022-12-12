import React from 'react';
export var anchorBlockIdFromId = function anchorBlockIdFromId(storyId) {
  return "anchor--".concat(storyId);
};
export var Anchor = function Anchor(_ref) {
  var storyId = _ref.storyId,
      children = _ref.children;
  return /*#__PURE__*/React.createElement("div", {
    id: anchorBlockIdFromId(storyId)
  }, children);
};