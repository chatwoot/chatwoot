import { ref, computed } from 'vue';
import { debounce } from '@chatwoot/utils';

/**
 * Calculates the relative position of a point from the center of an element
 *
 * @param {number} mouseX - The x-coordinate of the mouse pointer
 * @param {number} mouseY - The y-coordinate of the mouse pointer
 * @param {DOMRect} rect - The bounding client rectangle of the target element
 * @returns {{relativeX: number, relativeY: number}} Object containing x and y distances from center
 */
const calculateCenterOffset = (mouseX, mouseY, rect) => {
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
const applyRotationTransform = (relativeX, relativeY, angle) => {
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
const normalizeToPercentage = (rotatedX, rotatedY, width, height) => {
  // Convert to percentages (0-100%) relative to image dimensions
  // 50% represents the center point
  // The division by (width/2) maps the range [-width/2, width/2] to [-50%, 50%]
  // Adding 50% shifts this to [0%, 100%]
  return {
    x: Math.max(0, Math.min(100, 50 + (rotatedX / (width / 2)) * 50)),
    y: Math.max(0, Math.min(100, 50 + (rotatedY / (height / 2)) * 50)),
  };
};

// Composable for images in gallery view
export const useImageZoom = imageRef => {
  const MAX_ZOOM_LEVEL = 3;
  const MIN_ZOOM_LEVEL = 1;
  const DEFAULT_IMG_TRANSFORM_ORIGIN = 'center center';

  const zoomScale = ref(1);
  const imgTransformOriginPoint = ref(DEFAULT_IMG_TRANSFORM_ORIGIN);
  const activeImageRotation = ref(0);

  const imageWrapperStyle = computed(() => ({
    transform: `rotate(${activeImageRotation.value}deg)`,
  }));

  const imageStyle = computed(() => ({
    transform: `scale(${zoomScale.value})`,
    cursor: zoomScale.value < MAX_ZOOM_LEVEL ? 'zoom-in' : 'zoom-out',
    transformOrigin: `${imgTransformOriginPoint.value}`,
  }));

  // Resets the transform origin to center
  const resetTransformOrigin = () => {
    if (imageRef.value) {
      imgTransformOriginPoint.value = DEFAULT_IMG_TRANSFORM_ORIGIN;
    }
  };

  // Rotates the current image
  const onRotate = type => {
    if (!imageRef.value) return;
    resetTransformOrigin();

    const rotation = type === 'clockwise' ? 90 : -90;

    // ensure that the value of the rotation is within the range of -360 to 360 degrees
    activeImageRotation.value = (activeImageRotation.value + rotation) % 360;

    // Reset zoom when rotating
    zoomScale.value = 1;
    resetTransformOrigin();
  };

  /**
   * Calculates the appropriate transform origin point based on mouse position and image rotation
   * Used to create a natural zoom behavior where the image zooms toward/from the cursor position
   *
   * @param {number} x - The client X coordinate of the mouse pointer
   * @param {number} y - The client Y coordinate of the mouse pointer
   * @returns {{x: number, y: number}} Object containing the transform origin coordinates as percentages
   */
  const getZoomOrigin = (x, y) => {
    // Default to center
    if (!imageRef.value) return { x: 50, y: 50 };

    const rect = imageRef.value.getBoundingClientRect();

    // Step 1: Calculate offset from center
    const { relativeX, relativeY } = calculateCenterOffset(x, y, rect);

    // Step 2: Apply rotation transformation
    const { rotatedX, rotatedY } = applyRotationTransform(
      relativeX,
      relativeY,
      activeImageRotation.value
    );

    // Step 3: Convert to percentage coordinates
    return normalizeToPercentage(rotatedX, rotatedY, rect.width, rect.height);
  };

  // Handles zooming the image
  const onZoom = (scale, x, y) => {
    if (!imageRef.value) return;

    // Calculate new scale within bounds
    const newScale = Math.max(
      MIN_ZOOM_LEVEL,
      Math.min(MAX_ZOOM_LEVEL, zoomScale.value + scale)
    );

    // Skip if no change
    if (newScale === zoomScale.value) return;

    // Update transform origin based on mouse position and zoom scale is minimum
    if (x != null && y != null && zoomScale.value === MIN_ZOOM_LEVEL) {
      const { x: originX, y: originY } = getZoomOrigin(x, y);
      imgTransformOriginPoint.value = `${originX}% ${originY}%`;
    }

    // Apply the new scale
    zoomScale.value = newScale;
  };

  // Handles double-click zoom toggling
  const onDoubleClickZoomImage = e => {
    if (!imageRef.value) return;
    e.preventDefault();

    // Toggle between max zoom and min zoom
    const newScale =
      zoomScale.value >= MAX_ZOOM_LEVEL ? MIN_ZOOM_LEVEL : MAX_ZOOM_LEVEL;

    // Update transform origin based on mouse position
    const { x: originX, y: originY } = getZoomOrigin(e.clientX, e.clientY);
    imgTransformOriginPoint.value = `${originX}% ${originY}%`;

    // Apply the new scale
    zoomScale.value = newScale;
  };

  // Handles mouse wheel zooming for images
  const onWheelImageZoom = e => {
    if (!imageRef.value) return;
    e.preventDefault();

    const scale = e.deltaY > 0 ? -0.2 : 0.2;
    onZoom(scale, e.clientX, e.clientY);
  };

  /**
   * Sets transform origin to mouse position during hover.
   * Enables precise scroll/double-click zoom targeting by updating the
   * transform origin to cursor position. Only active at minimum zoom level.
   * Debounced (100ms) to improve performance during rapid mouse movement.
   */
  const onMouseMove = debounce(
    e => {
      if (!imageRef.value) return;
      if (zoomScale.value !== MIN_ZOOM_LEVEL) return;

      const { x: originX, y: originY } = getZoomOrigin(e.clientX, e.clientY);
      imgTransformOriginPoint.value = `${originX}% ${originY}%`;
    },
    100,
    false
  );

  /**
   * Resets transform origin to center when mouse leaves image.
   * Ensures button-based zooming works predictably after hover ends.
   * Uses slightly longer debounce (110ms) to avoid conflicts with onMouseMove.
   */
  const onMouseLeave = debounce(
    () => {
      if (!imageRef.value) return;
      if (zoomScale.value !== MIN_ZOOM_LEVEL) return;
      imgTransformOriginPoint.value = DEFAULT_IMG_TRANSFORM_ORIGIN;
    },
    110,
    false
  );

  const resetZoomAndRotation = () => {
    activeImageRotation.value = 0;
    zoomScale.value = 1;
    resetTransformOrigin();
  };

  return {
    zoomScale,
    imgTransformOriginPoint,
    activeImageRotation,
    imageWrapperStyle,
    imageStyle,
    getZoomOrigin,
    resetTransformOrigin,
    onRotate,
    onZoom,
    onDoubleClickZoomImage,
    onWheelImageZoom,
    onMouseMove,
    onMouseLeave,
    resetZoomAndRotation,
  };
};
