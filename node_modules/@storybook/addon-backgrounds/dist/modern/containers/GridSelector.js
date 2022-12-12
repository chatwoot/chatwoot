import React, { memo } from 'react';
import { useGlobals, useParameter } from '@storybook/api';
import { Icons, IconButton } from '@storybook/components';
import { PARAM_KEY as BACKGROUNDS_PARAM_KEY } from '../constants';
export const GridSelector = /*#__PURE__*/memo(() => {
  var _globals$BACKGROUNDS_;

  const [globals, updateGlobals] = useGlobals();
  const {
    grid
  } = useParameter(BACKGROUNDS_PARAM_KEY, {
    grid: {
      disable: false
    }
  });

  if (grid !== null && grid !== void 0 && grid.disable) {
    return null;
  }

  const isActive = ((_globals$BACKGROUNDS_ = globals[BACKGROUNDS_PARAM_KEY]) === null || _globals$BACKGROUNDS_ === void 0 ? void 0 : _globals$BACKGROUNDS_.grid) || false;
  return /*#__PURE__*/React.createElement(IconButton, {
    key: "background",
    active: isActive,
    title: "Apply a grid to the preview",
    onClick: () => updateGlobals({
      [BACKGROUNDS_PARAM_KEY]: Object.assign({}, globals[BACKGROUNDS_PARAM_KEY], {
        grid: !isActive
      })
    })
  }, /*#__PURE__*/React.createElement(Icons, {
    icon: "grid"
  }));
});