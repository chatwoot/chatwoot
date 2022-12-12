import global from 'global';
import dedent from 'ts-dedent';
import { logger } from '@storybook/client-logger';
const {
  document,
  window
} = global;
export const isReduceMotionEnabled = () => {
  const prefersReduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  return prefersReduceMotion.matches;
};
export const getBackgroundColorByName = (currentSelectedValue, backgrounds = [], defaultName) => {
  if (currentSelectedValue === 'transparent') {
    return 'transparent';
  }

  if (backgrounds.find(background => background.value === currentSelectedValue)) {
    return currentSelectedValue;
  }

  const defaultBackground = backgrounds.find(background => background.name === defaultName);

  if (defaultBackground) {
    return defaultBackground.value;
  }

  if (defaultName) {
    const availableColors = backgrounds.map(background => background.name).join(', ');
    logger.warn(dedent`
        Backgrounds Addon: could not find the default color "${defaultName}".
        These are the available colors for your story based on your configuration:
        ${availableColors}.
      `);
  }

  return 'transparent';
};
export const clearStyles = selector => {
  const selectors = Array.isArray(selector) ? selector : [selector];
  selectors.forEach(clearStyle);
};

const clearStyle = selector => {
  const element = document.getElementById(selector);

  if (element) {
    element.parentElement.removeChild(element);
  }
};

export const addGridStyle = (selector, css) => {
  const existingStyle = document.getElementById(selector);

  if (existingStyle) {
    if (existingStyle.innerHTML !== css) {
      existingStyle.innerHTML = css;
    }
  } else {
    const style = document.createElement('style');
    style.setAttribute('id', selector);
    style.innerHTML = css;
    document.head.appendChild(style);
  }
};
export const addBackgroundStyle = (selector, css, storyId) => {
  const existingStyle = document.getElementById(selector);

  if (existingStyle) {
    if (existingStyle.innerHTML !== css) {
      existingStyle.innerHTML = css;
    }
  } else {
    const style = document.createElement('style');
    style.setAttribute('id', selector);
    style.innerHTML = css;
    const gridStyleSelector = `addon-backgrounds-grid${storyId ? `-docs-${storyId}` : ''}`; // If grids already exist, we want to add the style tag BEFORE it so the background doesn't override grid

    const existingGridStyle = document.getElementById(gridStyleSelector);

    if (existingGridStyle) {
      existingGridStyle.parentElement.insertBefore(style, existingGridStyle);
    } else {
      document.head.appendChild(style);
    }
  }
};