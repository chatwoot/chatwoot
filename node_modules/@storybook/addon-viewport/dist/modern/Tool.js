const _excluded = ["name"],
      _excluded2 = ["width", "height"];

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

/* eslint-disable no-fallthrough */
import React, { Fragment, useEffect, useRef, memo } from 'react';
import memoize from 'memoizerific';
import { styled, Global, withTheme } from '@storybook/theming';
import { Icons, IconButton, WithTooltip, TooltipLinkList } from '@storybook/components';
import { useStorybookApi, useParameter, useAddonState } from '@storybook/api';
import { registerShortcuts } from './shortcuts';
import { PARAM_KEY, ADDON_ID } from './constants';
import { MINIMAL_VIEWPORTS } from './defaults';
const toList = memoize(50)(items => [...baseViewports, ...Object.entries(items).map(([id, _ref]) => {
  let {
    name
  } = _ref,
      rest = _objectWithoutPropertiesLoose(_ref, _excluded);

  return Object.assign({}, rest, {
    id,
    title: name
  });
})]);
const responsiveViewport = {
  id: 'reset',
  title: 'Reset viewport',
  styles: null,
  type: 'other'
};
const baseViewports = [responsiveViewport];
const toLinks = memoize(50)((list, active, set, state, close) => {
  return list.map(i => {
    switch (i.id) {
      case responsiveViewport.id:
        {
          if (active.id === i.id) {
            return null;
          }
        }

      default:
        {
          return Object.assign({}, i, {
            onClick: () => {
              set(Object.assign({}, state, {
                selected: i.id
              }));
              close();
            }
          });
        }
    }
  }).filter(Boolean);
});
const iframeId = 'storybook-preview-iframe';
const wrapperId = 'storybook-preview-wrapper';

const flip = _ref2 => {
  let {
    width,
    height
  } = _ref2,
      styles = _objectWithoutPropertiesLoose(_ref2, _excluded2);

  return Object.assign({}, styles, {
    height: width,
    width: height
  });
};

const ActiveViewportSize = styled.div(() => ({
  display: 'inline-flex'
}));
const ActiveViewportLabel = styled.div(({
  theme
}) => ({
  display: 'inline-block',
  textDecoration: 'none',
  padding: 10,
  fontWeight: theme.typography.weight.bold,
  fontSize: theme.typography.size.s2 - 1,
  lineHeight: '1',
  height: 40,
  border: 'none',
  borderTop: '3px solid transparent',
  borderBottom: '3px solid transparent',
  background: 'transparent'
}));
const IconButtonWithLabel = styled(IconButton)(() => ({
  display: 'inline-flex',
  alignItems: 'center'
}));
const IconButtonLabel = styled.div(({
  theme
}) => ({
  fontSize: theme.typography.size.s2 - 1,
  marginLeft: 10
}));

const getStyles = (prevStyles, styles, isRotated) => {
  if (styles === null) {
    return null;
  }

  const result = typeof styles === 'function' ? styles(prevStyles) : styles;
  return isRotated ? flip(result) : result;
};

export const ViewportTool = /*#__PURE__*/memo(withTheme(({
  theme
}) => {
  const {
    viewports = MINIMAL_VIEWPORTS,
    defaultViewport = responsiveViewport.id,
    disable
  } = useParameter(PARAM_KEY, {});
  const [state, setState] = useAddonState(ADDON_ID, {
    selected: defaultViewport,
    isRotated: false
  });
  const list = toList(viewports);
  const api = useStorybookApi();

  if (!list.find(i => i.id === defaultViewport)) {
    // eslint-disable-next-line no-console
    console.warn(`Cannot find "defaultViewport" of "${defaultViewport}" in addon-viewport configs, please check the "viewports" setting in the configuration.`);
  }

  useEffect(() => {
    registerShortcuts(api, setState, Object.keys(viewports));
  }, [viewports]);
  useEffect(() => {
    setState({
      selected: defaultViewport || (viewports[state.selected] ? state.selected : responsiveViewport.id),
      isRotated: state.isRotated
    });
  }, [defaultViewport]);
  const {
    selected,
    isRotated
  } = state;
  const item = list.find(i => i.id === selected) || list.find(i => i.id === defaultViewport) || list.find(i => i.default) || responsiveViewport;
  const ref = useRef();
  const styles = getStyles(ref.current, item.styles, isRotated);
  useEffect(() => {
    ref.current = styles;
  }, [item]);

  if (disable || Object.entries(viewports).length === 0) {
    return null;
  }

  return /*#__PURE__*/React.createElement(Fragment, null, /*#__PURE__*/React.createElement(WithTooltip, {
    placement: "top",
    trigger: "click",
    tooltip: ({
      onHide
    }) => /*#__PURE__*/React.createElement(TooltipLinkList, {
      links: toLinks(list, item, setState, state, onHide)
    }),
    closeOnClick: true
  }, /*#__PURE__*/React.createElement(IconButtonWithLabel, {
    key: "viewport",
    title: "Change the size of the preview",
    active: !!styles,
    onDoubleClick: () => {
      setState(Object.assign({}, state, {
        selected: responsiveViewport.id
      }));
    }
  }, /*#__PURE__*/React.createElement(Icons, {
    icon: "grow"
  }), styles ? /*#__PURE__*/React.createElement(IconButtonLabel, null, isRotated ? `${item.title} (L)` : `${item.title} (P)`) : null)), styles ? /*#__PURE__*/React.createElement(ActiveViewportSize, null, /*#__PURE__*/React.createElement(Global, {
    styles: {
      [`#${iframeId}`]: Object.assign({
        margin: `auto`,
        transition: 'width .3s, height .3s',
        position: 'relative',
        border: `1px solid black`,
        boxShadow: '0 0 100px 100vw rgba(0,0,0,0.5)'
      }, styles),
      [`#${wrapperId}`]: {
        padding: theme.layoutMargin,
        alignContent: 'center',
        alignItems: 'center',
        justifyContent: 'center',
        justifyItems: 'center',
        overflow: 'auto',
        display: 'grid',
        gridTemplateColumns: '100%',
        gridTemplateRows: '100%'
      }
    }
  }), /*#__PURE__*/React.createElement(ActiveViewportLabel, {
    title: "Viewport width"
  }, styles.width.replace('px', '')), /*#__PURE__*/React.createElement(IconButton, {
    key: "viewport-rotate",
    title: "Rotate viewport",
    onClick: () => {
      setState(Object.assign({}, state, {
        isRotated: !isRotated
      }));
    }
  }, /*#__PURE__*/React.createElement(Icons, {
    icon: "transfer"
  })), /*#__PURE__*/React.createElement(ActiveViewportLabel, {
    title: "Viewport height"
  }, styles.height.replace('px', ''))) : null);
}));