/**
 * Sorts an array of numbers in ascending order.
 * @param {number[]} arr - The array of numbers to be sorted.
 * @returns {number[]} - The sorted array.
 */
export function sortAsc(arr: number[]) {
  // .slice() is used to create a copy of the array so that the original array is not mutated
  return arr.slice().sort((a, b) => a - b);
}

/**
 * Calculates the quantile value of an array at a specified percentile.
 * @param {number[]} arr - The array of numbers to calculate the quantile value from.
 * @param {number} q - The percentile to calculate the quantile value for.
 * @returns {number} - The quantile value.
 */
export function quantile(arr: number[], q: number) {
  const sorted = sortAsc(arr); // Sort the array in ascending order
  return _quantileForSorted(sorted, q); // Calculate the quantile value
}

/**
 * Clamps a value between a minimum and maximum range.
 * @param {number} min - The minimum range.
 * @param {number} max - The maximum range.
 * @param {number} value - The value to be clamped.
 * @returns {number} - The clamped value.
 */
export function clamp(min: number, max: number, value: number) {
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}

/**
 * This method assumes the the array provided is already sorted in ascending order.
 * It's a helper method for the quantile method and should not be exported as is.
 *
 * @param {number[]} arr - The array of numbers to calculate the quantile value from.
 * @param {number} q - The percentile to calculate the quantile value for.
 * @returns {number} - The quantile value.
 */
function _quantileForSorted(sorted: number[], q: number) {
  const clamped = clamp(0, 1, q); // Clamp the percentile between 0 and 1
  const pos = (sorted.length - 1) * clamped; // Calculate the index of the element at the specified percentile
  const base = Math.floor(pos); // Find the index of the closest element to the specified percentile
  const rest = pos - base; // Calculate the decimal value between the closest elements

  // Interpolate the quantile value between the closest elements
  // Most libraries don't to the interpolation, but I'm just having fun here
  // also see https://en.wikipedia.org/wiki/Quantile#Estimating_quantiles_from_a_sample
  if (sorted[base + 1] !== undefined) {
    // in case the position was a integer, the rest will be 0 and the interpolation will be skipped
    return sorted[base] + rest * (sorted[base + 1] - sorted[base]);
  }

  // Return the closest element if there is no interpolation possible
  return sorted[base];
}

/**
 * Calculates the quantile values for an array of intervals.
 * @param {number[]} data - The array of numbers to calculate the quantile values from.
 * @param {number[]} intervals - The array of intervals to calculate the quantile values for.
 * @returns {number[]} - The array of quantile values for the intervals.
 */
export const getQuantileIntervals = (data: number[], intervals: number[]) => {
  // Sort the array in ascending order before looping through the intervals.
  // depending on the size of the array and the number of intervals, this can speed up the process by at least twice
  // for a random array of 100 numbers and 5 intervals, the speedup is 3x
  const sorted = sortAsc(data);

  return intervals.map(interval => {
    return _quantileForSorted(sorted, interval);
  });
};

/**
 * Calculates the relative position of a point from the center of an element
 *
 * @param {number} mouseX - The x-coordinate of the mouse pointer
 * @param {number} mouseY - The y-coordinate of the mouse pointer
 * @param {DOMRect} rect - The bounding client rectangle of the target element
 * @returns {{relativeX: number, relativeY: number}} Object containing x and y distances from center
 */
export const calculateCenterOffset = (
  mouseX: number,
  mouseY: number,
  rect: DOMRect
) => {
  const centerX = rect.left + rect.width / 2;
  const centerY = rect.top + rect.height / 2;

  return {
    relativeX: mouseX - centerX,
    relativeY: mouseY - centerY,
  };
};

/**
 * Applies a rotation matrix to coordinates
 * Used to adjust mouse coordinates based on the current rotation of the image
 * This function implements a standard 2D rotation matrix transformation:
 * [x']   [cos(θ) -sin(θ)] [x]
 * [y'] = [sin(θ)  cos(θ)] [y]
 *
 * @see {@link https://mathworld.wolfram.com/RotationMatrix.html} for mathematical derivation
 *
 * @param {number} relativeX - X-coordinate relative to center before rotation
 * @param {number} relativeY - Y-coordinate relative to center before rotation
 * @param {number} angle - Rotation angle in degrees
 * @returns {{rotatedX: number, rotatedY: number}} Coordinates after applying rotation matrix
 */
export const applyRotationTransform = (
  relativeX: number,
  relativeY: number,
  angle: number
) => {
  const radians = (angle * Math.PI) / 180;
  const cos = Math.cos(-radians);
  const sin = Math.sin(-radians);

  return {
    rotatedX: relativeX * cos - relativeY * sin,
    rotatedY: relativeX * sin + relativeY * cos,
  };
};

/**
 * Converts absolute rotated coordinates to percentage values relative to image dimensions
 * Ensures values are clamped between 0-100% for valid CSS transform-origin properties
 *
 * @param {number} rotatedX - X-coordinate after rotation transformation
 * @param {number} rotatedY - Y-coordinate after rotation transformation
 * @param {number} width - Width of the target element
 * @param {number} height - Height of the target element
 * @returns {{x: number, y: number}} Normalized coordinates as percentages (0-100%)
 */
export const normalizeToPercentage = (
  rotatedX: number,
  rotatedY: number,
  width: number,
  height: number
) => {
  // Convert to percentages (0-100%) relative to image dimensions
  // 50% represents the center point
  // The division by (width/2) maps the range [-width/2, width/2] to [-50%, 50%]
  // Adding 50% shifts this to [0%, 100%]
  return {
    x: Math.max(0, Math.min(100, 50 + (rotatedX / (width / 2)) * 50)),
    y: Math.max(0, Math.min(100, 50 + (rotatedY / (height / 2)) * 50)),
  };
};
