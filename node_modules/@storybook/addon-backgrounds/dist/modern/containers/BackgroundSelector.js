import React, { Fragment, useCallback, useMemo, memo } from 'react';
import memoize from 'memoizerific';
import { useParameter, useGlobals } from '@storybook/api';
import { logger } from '@storybook/client-logger';
import { Icons, IconButton, WithTooltip, TooltipLinkList } from '@storybook/components';
import { PARAM_KEY as BACKGROUNDS_PARAM_KEY } from '../constants';
import { ColorIcon } from '../components/ColorIcon';
import { getBackgroundColorByName } from '../helpers';
const createBackgroundSelectorItem = memoize(1000)((id, name, value, hasSwatch, change, active) => ({
  id: id || name,
  title: name,
  onClick: () => {
    change({
      selected: value,
      name
    });
  },
  value,
  right: hasSwatch ? /*#__PURE__*/React.createElement(ColorIcon, {
    background: value
  }) : undefined,
  active
}));
const getDisplayedItems = memoize(10)((backgrounds, selectedBackgroundColor, change) => {
  const backgroundSelectorItems = backgrounds.map(({
    name,
    value
  }) => createBackgroundSelectorItem(null, name, value, true, change, value === selectedBackgroundColor));

  if (selectedBackgroundColor !== 'transparent') {
    return [createBackgroundSelectorItem('reset', 'Clear background', 'transparent', null, change, false), ...backgroundSelectorItems];
  }

  return backgroundSelectorItems;
});
const DEFAULT_BACKGROUNDS_CONFIG = {
  default: null,
  disable: true,
  values: []
};
export const BackgroundSelector = /*#__PURE__*/memo(() => {
  var _globals$BACKGROUNDS_;

  const backgroundsConfig = useParameter(BACKGROUNDS_PARAM_KEY, DEFAULT_BACKGROUNDS_CONFIG);
  const [globals, updateGlobals] = useGlobals();
  const globalsBackgroundColor = (_globals$BACKGROUNDS_ = globals[BACKGROUNDS_PARAM_KEY]) === null || _globals$BACKGROUNDS_ === void 0 ? void 0 : _globals$BACKGROUNDS_.value;
  const selectedBackgroundColor = useMemo(() => {
    return getBackgroundColorByName(globalsBackgroundColor, backgroundsConfig.values, backgroundsConfig.default);
  }, [backgroundsConfig, globalsBackgroundColor]);

  if (Array.isArray(backgroundsConfig)) {
    logger.warn('Addon Backgrounds api has changed in Storybook 6.0. Please refer to the migration guide: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md');
  }

  const onBackgroundChange = useCallback(value => {
    updateGlobals({
      [BACKGROUNDS_PARAM_KEY]: Object.assign({}, globals[BACKGROUNDS_PARAM_KEY], {
        value
      })
    });
  }, [backgroundsConfig, globals, updateGlobals]);

  if (backgroundsConfig.disable) {
    return null;
  }

  return /*#__PURE__*/React.createElement(Fragment, null, /*#__PURE__*/React.createElement(WithTooltip, {
    placement: "top",
    trigger: "click",
    closeOnClick: true,
    tooltip: ({
      onHide
    }) => {
      return /*#__PURE__*/React.createElement(TooltipLinkList, {
        links: getDisplayedItems(backgroundsConfig.values, selectedBackgroundColor, ({
          selected
        }) => {
          if (selectedBackgroundColor !== selected) {
            onBackgroundChange(selected);
          }

          onHide();
        })
      });
    }
  }, /*#__PURE__*/React.createElement(IconButton, {
    key: "background",
    title: "Change the background of the preview",
    active: selectedBackgroundColor !== 'transparent'
  }, /*#__PURE__*/React.createElement(Icons, {
    icon: "photo"
  }))));
});