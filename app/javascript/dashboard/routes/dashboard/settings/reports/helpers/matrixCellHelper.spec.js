import {
  CELL_INTENSITY_CLASSES,
  intensityClassFor,
  isWeekend,
} from './matrixCellHelper';

describe('intensityClassFor', () => {
  it('returns no class for zero', () => {
    expect(intensityClassFor(0, 10)).toBe('');
  });

  it('uses the first band for the smallest non-zero value', () => {
    expect(intensityClassFor(1, 10)).toBe(CELL_INTENSITY_CLASSES[0]);
  });

  it('uses the fifth band for the maximum value', () => {
    expect(intensityClassFor(10, 10)).toBe(CELL_INTENSITY_CLASSES[4]);
  });

  it('clamps values above the maximum to the fifth band', () => {
    expect(intensityClassFor(11, 10)).toBe(CELL_INTENSITY_CLASSES[4]);
  });
});

describe('isWeekend', () => {
  it('identifies Saturday and Sunday as weekend days', () => {
    expect(isWeekend(new Date(2026, 7, 1))).toBe(true);
    expect(isWeekend(new Date(2026, 7, 2))).toBe(true);
  });

  it('does not identify a weekday as a weekend day', () => {
    expect(isWeekend(new Date(2026, 7, 3))).toBe(false);
  });
});
