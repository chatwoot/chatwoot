import { useMemo, useEffect } from '@storybook/addons';
import { clearStyles, addOutlineStyles } from './helpers';
import { PARAM_KEY } from './constants';
import outlineCSS from './outlineCSS';
export const withOutline = (StoryFn, context) => {
  const {
    globals
  } = context;
  const isActive = globals[PARAM_KEY] === true;
  const isInDocs = context.viewMode === 'docs';
  const outlineStyles = useMemo(() => {
    const selector = isInDocs ? `#anchor--${context.id} .docs-story` : '.sb-show-main';
    return outlineCSS(selector);
  }, [context]);
  useEffect(() => {
    const selectorId = isInDocs ? `addon-outline-docs-${context.id}` : `addon-outline`;

    if (!isActive) {
      clearStyles(selectorId);
    } else {
      addOutlineStyles(selectorId, outlineStyles);
    }

    return () => {
      clearStyles(selectorId);
    };
  }, [isActive, outlineStyles, context]);
  return StoryFn();
};