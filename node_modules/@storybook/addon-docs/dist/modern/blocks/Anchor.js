import React from 'react';
export const anchorBlockIdFromId = storyId => `anchor--${storyId}`;
export const Anchor = ({
  storyId,
  children
}) => /*#__PURE__*/React.createElement("div", {
  id: anchorBlockIdFromId(storyId)
}, children);