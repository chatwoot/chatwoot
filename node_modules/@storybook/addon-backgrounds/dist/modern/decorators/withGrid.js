import dedent from 'ts-dedent';
import deprecate from 'util-deprecate';
import { useMemo, useEffect } from '@storybook/addons';
import { clearStyles, addGridStyle } from '../helpers';
import { PARAM_KEY as BACKGROUNDS_PARAM_KEY } from '../constants';
const deprecatedCellSizeWarning = deprecate(() => {}, dedent`
    Backgrounds Addon: The cell size parameter has been changed.

    - parameters.grid.cellSize should now be parameters.backgrounds.grid.cellSize
    See https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-grid-parameter
  `);
export const withGrid = (StoryFn, context) => {
  var _globals$BACKGROUNDS_, _parameters$grid, _gridParameters$offse, _gridParameters$offse2;

  const {
    globals,
    parameters
  } = context;
  const gridParameters = parameters[BACKGROUNDS_PARAM_KEY].grid;
  const isActive = ((_globals$BACKGROUNDS_ = globals[BACKGROUNDS_PARAM_KEY]) === null || _globals$BACKGROUNDS_ === void 0 ? void 0 : _globals$BACKGROUNDS_.grid) === true && gridParameters.disable !== true;
  const {
    cellAmount,
    cellSize,
    opacity
  } = gridParameters;
  const isInDocs = context.viewMode === 'docs';
  let gridSize;

  if ((_parameters$grid = parameters.grid) !== null && _parameters$grid !== void 0 && _parameters$grid.cellSize) {
    gridSize = parameters.grid.cellSize;
    deprecatedCellSizeWarning();
  } else {
    gridSize = cellSize;
  }

  const isLayoutPadded = parameters.layout === undefined || parameters.layout === 'padded'; // 16px offset in the grid to account for padded layout

  const defaultOffset = isLayoutPadded ? 16 : 0;
  const offsetX = (_gridParameters$offse = gridParameters.offsetX) !== null && _gridParameters$offse !== void 0 ? _gridParameters$offse : isInDocs ? 20 : defaultOffset;
  const offsetY = (_gridParameters$offse2 = gridParameters.offsetY) !== null && _gridParameters$offse2 !== void 0 ? _gridParameters$offse2 : isInDocs ? 20 : defaultOffset;
  const gridStyles = useMemo(() => {
    const selector = context.viewMode === 'docs' ? `#anchor--${context.id} .docs-story` : '.sb-show-main';
    const backgroundSize = [`${gridSize * cellAmount}px ${gridSize * cellAmount}px`, `${gridSize * cellAmount}px ${gridSize * cellAmount}px`, `${gridSize}px ${gridSize}px`, `${gridSize}px ${gridSize}px`].join(', ');
    return `
      ${selector} {
        background-size: ${backgroundSize} !important;
        background-position: ${offsetX}px ${offsetY}px, ${offsetX}px ${offsetY}px, ${offsetX}px ${offsetY}px, ${offsetX}px ${offsetY}px !important;
        background-blend-mode: difference !important;
        background-image: linear-gradient(rgba(130, 130, 130, ${opacity}) 1px, transparent 1px),
         linear-gradient(90deg, rgba(130, 130, 130, ${opacity}) 1px, transparent 1px),
         linear-gradient(rgba(130, 130, 130, ${opacity / 2}) 1px, transparent 1px),
         linear-gradient(90deg, rgba(130, 130, 130, ${opacity / 2}) 1px, transparent 1px) !important;
      }
    `;
  }, [gridSize]);
  useEffect(() => {
    const selectorId = context.viewMode === 'docs' ? `addon-backgrounds-grid-docs-${context.id}` : `addon-backgrounds-grid`;

    if (!isActive) {
      clearStyles(selectorId);
      return;
    }

    addGridStyle(selectorId, gridStyles);
  }, [isActive, gridStyles, context]);
  return StoryFn();
};