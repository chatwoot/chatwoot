import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import {
  hexToRgb,
  generateColorTones,
  applyThemeColors,
  initializeThemeColor,
} from 'shared/helpers/themeColor';

describe('#hexToRgb', () => {
  it('converts hex color to RGB object', () => {
    const rgb = hexToRgb('#FF0000');
    expect(rgb.r).toBe(255);
    expect(rgb.g).toBe(0);
    expect(rgb.b).toBe(0);
  });

  it('handles lowercase hex colors', () => {
    const rgb = hexToRgb('#00ff00');
    expect(rgb.r).toBe(0);
    expect(rgb.g).toBe(255);
    expect(rgb.b).toBe(0);
  });

  it('converts white hex', () => {
    const rgb = hexToRgb('#FFFFFF');
    expect(rgb.r).toBe(255);
    expect(rgb.g).toBe(255);
    expect(rgb.b).toBe(255);
  });

  it('converts black hex', () => {
    const rgb = hexToRgb('#000000');
    expect(rgb.r).toBe(0);
    expect(rgb.g).toBe(0);
    expect(rgb.b).toBe(0);
  });
});

describe('#generateColorTones', () => {
  it('generates 12 tones for light mode', () => {
    const tones = generateColorTones('#2781F6', false);
    expect(Object.keys(tones)).toHaveLength(12);
  });

  it('generates 12 tones for dark mode', () => {
    const tones = generateColorTones('#2781F6', true);
    expect(Object.keys(tones)).toHaveLength(12);
  });

  it('returns RGB strings in correct format', () => {
    const tones = generateColorTones('#2781F6', false);
    Object.values(tones).forEach(rgb => {
      expect(rgb).toMatch(/^\d+ \d+ \d+$/);
    });
  });

  it('generates different tones for light and dark modes', () => {
    const lightTones = generateColorTones('#2781F6', false);
    const darkTones = generateColorTones('#2781F6', true);

    // Tones should be different between light and dark
    const lightTone1 = lightTones[1];
    const darkTone1 = darkTones[1];
    expect(lightTone1).not.toBe(darkTone1);
  });

  it('creates tones numbered from 1 to 12', () => {
    const tones = generateColorTones('#FF0000', false);
    for (let i = 1; i <= 12; i += 1) {
      expect(tones[i]).toBeDefined();
    }
  });
});

describe('#applyThemeColors', () => {
  beforeEach(() => {
    document.documentElement.style.cssText = '';
    const existingStyle = document.getElementById('chatwoot-theme-colors');
    if (existingStyle) {
      existingStyle.remove();
    }
  });

  afterEach(() => {
    document.documentElement.style.cssText = '';
    const style = document.getElementById('chatwoot-theme-colors');
    if (style) {
      style.remove();
    }
  });

  it('sets light theme CSS variables on document root', () => {
    applyThemeColors('#2781F6');

    const tone1Value = getComputedStyle(
      document.documentElement
    ).getPropertyValue('--dl-primary-color-1');
    expect(tone1Value.trim()).toBeTruthy();
  });

  it('creates dark theme style element', () => {
    applyThemeColors('#2781F6');

    const darkStyle = document.getElementById('chatwoot-theme-colors');
    expect(darkStyle).toBeTruthy();
  });

  it('does not apply colors for invalid hex', () => {
    const initialStyles = document.documentElement.getAttribute('style') || '';
    applyThemeColors('invalid');
    const finalStyles = document.documentElement.getAttribute('style') || '';

    expect(finalStyles).toBe(initialStyles);
  });

  it('does not apply colors for non-hex string', () => {
    const initialStyles = document.documentElement.getAttribute('style') || '';
    applyThemeColors('red');
    const finalStyles = document.documentElement.getAttribute('style') || '';

    expect(finalStyles).toBe(initialStyles);
  });

  it('replaces existing dark theme style when called multiple times', () => {
    applyThemeColors('#2781F6');
    const firstStyle = document.getElementById('chatwoot-theme-colors');

    applyThemeColors('#FF0000');
    const secondStyle = document.getElementById('chatwoot-theme-colors');

    expect(firstStyle).not.toBe(secondStyle);
    expect(document.querySelectorAll('#chatwoot-theme-colors')).toHaveLength(1);
  });

  it('sets CSS variables with RGB values', () => {
    applyThemeColors('#0000FF');

    const tone6Value = getComputedStyle(
      document.documentElement
    ).getPropertyValue('--dl-primary-color-6');
    const rgbMatch = tone6Value.trim().match(/^(\d+) (\d+) (\d+)$/);
    expect(rgbMatch).toBeTruthy();
  });
});

describe('#initializeThemeColor', () => {
  beforeEach(() => {
    document.documentElement.style.cssText = '';
    const existingStyle = document.getElementById('chatwoot-theme-colors');
    if (existingStyle) {
      existingStyle.remove();
    }
  });

  afterEach(() => {
    document.documentElement.style.cssText = '';
    const style = document.getElementById('chatwoot-theme-colors');
    if (style) {
      style.remove();
    }
  });

  it('calls applyThemeColors with the provided hex', () => {
    initializeThemeColor('#2781F6');

    const tone1Value = getComputedStyle(
      document.documentElement
    ).getPropertyValue('--dl-primary-color-1');
    expect(tone1Value.trim()).toBeTruthy();
  });

  it('applies theme colors on initialization', () => {
    initializeThemeColor('#FF5733');

    const darkStyle = document.getElementById('chatwoot-theme-colors');
    expect(darkStyle).toBeTruthy();
    expect(darkStyle.textContent).toContain('--dl-primary-color');
  });
});
