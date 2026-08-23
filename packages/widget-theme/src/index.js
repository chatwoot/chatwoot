// [whisker] Widget theme applier.
// Reads a Whisker theme (inline object or URL to a theme.json) and applies it to
// the launcher bubble + iframe host page. Isolated: no upstream behavior changes.

import { resolveIconMarkup } from './icons';
import { injectMotionStyles, motionClassFor } from './motions';
import defaultTheme from '../themes/paw-blob.json';

const STYLE_ID = 'ws-widget-theme-style';

export const loadTheme = async themeOrUrl => {
  if (!themeOrUrl) return null;
  if (typeof themeOrUrl === 'object') return themeOrUrl;
  try {
    const response = await fetch(themeOrUrl);
    return await response.json();
  } catch {
    return null;
  }
};

export const buildIconSource = (icon, color = '#ffffff') => {
  const markup = resolveIconMarkup(icon);
  if (!markup) return icon; // assume URL / data-URI
  const tinted = markup
    .split('#ffffff')
    .join(color)
    .split('#FFFFFF')
    .join(color);
  return `data:image/svg+xml;utf8,${encodeURIComponent(tinted)}`;
};

const applyColors = colors => {
  if (!colors) return;
  const root = document.documentElement.style;
  root.setProperty('--ws-widget-primary', colors.primary);
  root.setProperty('--ws-widget-bubble-icon', colors.bubbleIcon || '#ffffff');
  root.setProperty('--ws-widget-accent', colors.accent || colors.primary);
};

export const applyWidgetTheme = async (theme, targets = {}) => {
  const resolved = { ...(defaultTheme || {}), ...theme };
  injectMotionStyles();

  const style =
    document.getElementById(STYLE_ID) || document.createElement('style');
  style.id = STYLE_ID;

  // Bubble background follows the theme primary via CSS var override on the holder
  applyColors(resolved.colors);

  // Icon swap
  const iconSrc =
    resolved.icon && resolved.colors
      ? buildIconSource(resolved.icon, resolved.colors.bubbleIcon || '#ffffff')
      : resolved.icon
        ? buildIconSource(resolved.icon)
        : null;
  const bubbleIconEl = document.getElementById('woot-widget-bubble-icon');
  if (iconSrc && bubbleIconEl && bubbleIconEl.tagName !== 'IMG') {
    const img = document.createElement('img');
    img.id = 'woot-widget-bubble-icon';
    img.src = iconSrc;
    img.alt = '';
    img.width = 28;
    img.height = 28;
    img.style.pointerEvents = 'none';
    bubbleIconEl.replaceWith(img);
  } else if (iconSrc && bubbleIconEl?.tagName === 'IMG') {
    bubbleIconEl.src = iconSrc;
  }

  // Motion preset
  const bubble = targets.chatBubble || document.querySelector('.woot-widget-bubble');
  if (bubble) {
    bubble.classList.remove(
      'ws-motion--bounce',
      'ws-motion--tada',
      'ws-motion--wiggle',
      'ws-motion--hop'
    );
    const motionClass = motionClassFor(resolved.motion?.launcher);
    if (
      motionClass &&
      (resolved.motion?.trigger === 'always' || !resolved.motion?.trigger)
    ) {
      bubble.classList.add(...motionClass.split(' '));
    }
  }
  return resolved;
};

export const startRecurringMotion = (theme, intervalSeconds = 20) => {
  const bubble = document.querySelector('.woot-widget-bubble');
  const motionClass = motionClassFor(theme?.motion?.launcher);
  if (!bubble || !motionClass || theme?.motion?.launcher === 'none') return null;
  const ms = Math.max(5, intervalSeconds) * 1000;
  return setInterval(() => {
    bubble.classList.remove(...motionClass.split(' '));
    // force reflow so the animation restarts
    void bubble.offsetWidth;
    bubble.classList.add(...motionClass.split(' '));
  }, ms);
};
