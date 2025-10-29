import { toHex, getContrast } from 'color2k';
import {
  isWidgetColorLighter,
  adjustColorForContrast,
} from 'shared/helpers/colorHelper';

describe('#isWidgetColorLighter', () => {
  it('returns true if color is lighter', () => {
    expect(isWidgetColorLighter('#ffffff')).toEqual(true);
  });
  it('returns false if color is darker', () => {
    expect(isWidgetColorLighter('#000000')).toEqual(false);
  });
});

describe('#adjustColorForContrast', () => {
  const targetRatio = 3.1;

  const getContrastRatio = (color1, color2) => {
    // getContrast from 'color2k'
    return getContrast(color1, color2);
  };

  it('adjusts a color to meet the contrast ratio against a light background', () => {
    const color = '#ff0000';
    const backgroundColor = '#ffffff';
    const adjustedColor = adjustColorForContrast(color, backgroundColor);
    const ratio = getContrastRatio(adjustedColor, backgroundColor);

    expect(ratio).toBeGreaterThanOrEqual(targetRatio);
  });

  it('adjusts a color to meet the contrast ratio against a dark background', () => {
    const color = '#00ff00';
    const backgroundColor = '#000000';
    const adjustedColor = adjustColorForContrast(color, backgroundColor);
    const ratio = getContrastRatio(adjustedColor, backgroundColor);

    expect(ratio).toBeGreaterThanOrEqual(targetRatio);
  });

  it('returns a string representation of the color', () => {
    const color = '#00ff00';
    const backgroundColor = '#000000';
    const adjustedColor = adjustColorForContrast(color, backgroundColor);

    expect(typeof adjustedColor).toEqual('string');
  });

  it('handles cases where the color already meets the contrast ratio', () => {
    const color = '#000000';
    const backgroundColor = '#ffffff';
    const adjustedColor = adjustColorForContrast(color, backgroundColor);
    const ratio = getContrastRatio(adjustedColor, backgroundColor);

    expect(ratio).toBeGreaterThanOrEqual(targetRatio);
    expect(adjustedColor).toEqual(toHex(color));
  });

  it('does not modify a color that already exceeds the contrast ratio', () => {
    const color = '#000000';
    const backgroundColor = '#ffffff';
    const adjustedColor = adjustColorForContrast(color, backgroundColor);

    expect(adjustedColor).toEqual(toHex(color));
  });
});
