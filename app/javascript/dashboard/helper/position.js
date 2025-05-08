/**
 * Calculates the optimal position for a popup element to ensure it remains within viewport bounds
 *
 * @param {number} x - The initial x-coordinate (left position) for the element
 * @param {number} y - The initial y-coordinate (top position) for the element
 * @param {number} menuW - The width of the element to position
 * @param {number} menuH - The height of the element to position
 * @param {number} windowW - The width of the viewport
 * @param {number} windowH - The height of the viewport
 * @param {number} [padding=16] - Minimum padding from viewport edges (in pixels)
 * @returns {Object} An object containing the adjusted { left, top } coordinates
 */
export const calculatePosition = (
  x,
  y,
  menuW,
  menuH,
  windowW,
  windowH,
  padding = 16
) => {
  // Initial position
  let left = x;
  let top = y;

  // Boundary checks
  const isOverflowingRight = left + menuW > windowW - padding;
  const isOverflowingBottom = top + menuH > windowH - padding;

  // Adjust position if overflowing
  if (isOverflowingRight) left = windowW - menuW - padding;
  if (isOverflowingBottom) top = windowH - menuH - padding;

  return {
    left: Math.max(padding, left),
    top: Math.max(padding, top),
  };
};
