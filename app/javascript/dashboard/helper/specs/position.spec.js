import { calculatePosition } from '../position';

describe('calculatePosition', () => {
  const WINDOW_WIDTH = 1024;
  const WINDOW_HEIGHT = 768;
  const MENU_WIDTH = 400;
  const MENU_HEIGHT = 300;
  const DEFAULT_PADDING = 16;

  test('returns the original position when element fits within viewport', () => {
    const x = 100;
    const y = 100;

    const result = calculatePosition(
      x,
      y,
      MENU_WIDTH,
      MENU_HEIGHT,
      WINDOW_WIDTH,
      WINDOW_HEIGHT
    );

    expect(result).toEqual({ left: x, top: y });
  });

  test('adjusts position when overflowing right edge', () => {
    const x = WINDOW_WIDTH - 100; // Too far right
    const y = 100;

    const result = calculatePosition(
      x,
      y,
      MENU_WIDTH,
      MENU_HEIGHT,
      WINDOW_WIDTH,
      WINDOW_HEIGHT
    );

    const expectedLeft = WINDOW_WIDTH - MENU_WIDTH - DEFAULT_PADDING;
    expect(result).toEqual({ left: expectedLeft, top: y });
  });

  test('adjusts position when overflowing bottom edge', () => {
    const x = 100;
    const y = WINDOW_HEIGHT - 100; // Too far down

    const result = calculatePosition(
      x,
      y,
      MENU_WIDTH,
      MENU_HEIGHT,
      WINDOW_WIDTH,
      WINDOW_HEIGHT
    );

    const expectedTop = WINDOW_HEIGHT - MENU_HEIGHT - DEFAULT_PADDING;
    expect(result).toEqual({ left: x, top: expectedTop });
  });

  test('adjusts position when overflowing both right and bottom edges', () => {
    const x = WINDOW_WIDTH - 100; // Too far right
    const y = WINDOW_HEIGHT - 100; // Too far down

    const result = calculatePosition(
      x,
      y,
      MENU_WIDTH,
      MENU_HEIGHT,
      WINDOW_WIDTH,
      WINDOW_HEIGHT
    );

    const expectedLeft = WINDOW_WIDTH - MENU_WIDTH - DEFAULT_PADDING;
    const expectedTop = WINDOW_HEIGHT - MENU_HEIGHT - DEFAULT_PADDING;
    expect(result).toEqual({ left: expectedLeft, top: expectedTop });
  });

  test('ensures minimum padding from left edge', () => {
    const x = -50; // Position would be off-screen to the left
    const y = 100;

    const result = calculatePosition(
      x,
      y,
      MENU_WIDTH,
      MENU_HEIGHT,
      WINDOW_WIDTH,
      WINDOW_HEIGHT
    );

    expect(result).toEqual({ left: DEFAULT_PADDING, top: y });
  });

  test('ensures minimum padding from top edge', () => {
    const x = 100;
    const y = -50; // Position would be off-screen at the top

    const result = calculatePosition(
      x,
      y,
      MENU_WIDTH,
      MENU_HEIGHT,
      WINDOW_WIDTH,
      WINDOW_HEIGHT
    );

    expect(result).toEqual({ left: x, top: DEFAULT_PADDING });
  });

  test('handles case when element is larger than viewport width', () => {
    const x = 100;
    const y = 100;
    const largeWidth = WINDOW_WIDTH + 200; // Wider than window

    const result = calculatePosition(
      x,
      y,
      largeWidth,
      MENU_HEIGHT,
      WINDOW_WIDTH,
      WINDOW_HEIGHT
    );

    // Should position at minimum padding
    expect(result).toEqual({ left: DEFAULT_PADDING, top: y });
  });

  test('handles case when element is larger than viewport height', () => {
    const x = 100;
    const y = 100;
    const largeHeight = WINDOW_HEIGHT + 200; // Taller than window

    const result = calculatePosition(
      x,
      y,
      MENU_WIDTH,
      largeHeight,
      WINDOW_WIDTH,
      WINDOW_HEIGHT
    );

    // Should position at minimum padding
    expect(result).toEqual({ left: x, top: DEFAULT_PADDING });
  });

  test('accepts custom padding value', () => {
    const x = WINDOW_WIDTH - 100;
    const y = WINDOW_HEIGHT - 100;
    const customPadding = 32;

    const result = calculatePosition(
      x,
      y,
      MENU_WIDTH,
      MENU_HEIGHT,
      WINDOW_WIDTH,
      WINDOW_HEIGHT,
      customPadding
    );

    const expectedLeft = WINDOW_WIDTH - MENU_WIDTH - customPadding;
    const expectedTop = WINDOW_HEIGHT - MENU_HEIGHT - customPadding;
    expect(result).toEqual({ left: expectedLeft, top: expectedTop });
  });

  test('ensures custom minimum padding from edges', () => {
    const x = -50;
    const y = -50;
    const customPadding = 32;

    const result = calculatePosition(
      x,
      y,
      MENU_WIDTH,
      MENU_HEIGHT,
      WINDOW_WIDTH,
      WINDOW_HEIGHT,
      customPadding
    );

    expect(result).toEqual({ left: customPadding, top: customPadding });
  });
});
