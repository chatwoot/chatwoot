<script setup>
import { ref, computed, useTemplateRef } from 'vue';
import { debounce } from '@chatwoot/utils';

const props = defineProps({
  attachment: {
    type: Object,
    required: true,
  },
  activeImageRotation: {
    type: Number,
    required: true,
  },
  zoomScale: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['update:zoomScale']);

const MAX_ZOOM_LEVEL = 3;
const MIN_ZOOM_LEVEL = 1;
const DEFAULT_IMG_TRANSFORM_ORIGIN = 'center center';

const imgTransformOriginPoint = ref(DEFAULT_IMG_TRANSFORM_ORIGIN);
const imageRef = useTemplateRef('imageRef');

const imageWrapperStyle = computed(() => ({
  transform: `rotate(${props.activeImageRotation}deg)`,
}));

const imageStyle = computed(() => ({
  transform: `scale(${props.zoomScale})`,
  cursor: props.zoomScale < MAX_ZOOM_LEVEL ? 'zoom-in' : 'zoom-out',
  transformOrigin: `${imgTransformOriginPoint.value}`,
}));

// Resets the transform origin to center
const resetTransformOrigin = () => {
  if (imageRef.value) {
    imgTransformOriginPoint.value = DEFAULT_IMG_TRANSFORM_ORIGIN;
  }
};

// Calculates the zoom origin based on cursor position and image rotation
const getZoomOrigin = (x, y) => {
  if (!imageRef.value) return { x: 50, y: 50 };

  const { left, top, width, height } = imageRef.value.getBoundingClientRect();
  const centerX = left + width / 2;
  const centerY = top + height / 2;

  // Calculate relative position from the center
  const relativeX = x - centerX;
  const relativeY = y - centerY;

  // Apply rotation transformation
  const angle = (props.activeImageRotation * Math.PI) / 180;
  const cos = Math.cos(-angle);
  const sin = Math.sin(-angle);

  const rotatedX = relativeX * cos - relativeY * sin;
  const rotatedY = relativeX * sin + relativeY * cos;

  // Convert to percentages and clamp between 0-100%
  return {
    x: Math.max(0, Math.min(100, 50 + (rotatedX / (width / 2)) * 50)),
    y: Math.max(0, Math.min(100, 50 + (rotatedY / (height / 2)) * 50)),
  };
};

// Handles zooming the image
const onZoom = (scale, x, y) => {
  if (!imageRef.value) return;

  // Calculate new scale within bounds
  const newScale = Math.max(
    MIN_ZOOM_LEVEL,
    Math.min(MAX_ZOOM_LEVEL, props.zoomScale + scale)
  );

  // Skip if no change
  if (newScale === props.zoomScale) return;

  // Update transform origin based on mouse position
  if (x != null && y != null) {
    const { x: originX, y: originY } = getZoomOrigin(x, y);
    imgTransformOriginPoint.value = `${originX}% ${originY}%`;
  }

  // Apply the new scale
  emit('update:zoomScale', newScale);
};

// Handles double-click zoom toggling
const onDoubleClickZoomImage = e => {
  if (!imageRef.value) return;
  e.preventDefault();

  // Toggle between max zoom and min zoom
  const newScale =
    props.zoomScale >= MAX_ZOOM_LEVEL ? MIN_ZOOM_LEVEL : MAX_ZOOM_LEVEL;

  // Update transform origin based on mouse position
  const { x: originX, y: originY } = getZoomOrigin(e.clientX, e.clientY);
  imgTransformOriginPoint.value = `${originX}% ${originY}%`;

  // Apply the new scale
  emit('update:zoomScale', newScale);
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
    if (props.zoomScale !== MIN_ZOOM_LEVEL) return;

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
    if (props.zoomScale !== MIN_ZOOM_LEVEL) return;
    imgTransformOriginPoint.value = DEFAULT_IMG_TRANSFORM_ORIGIN;
  },
  110,
  false
);

// Expose methods to parent
defineExpose({
  resetTransformOrigin,
  onZoom,
});
</script>

<template>
  <div
    :style="imageWrapperStyle"
    class="flex items-center justify-center origin-center"
    :class="{
      // Adjust dimensions when rotated 90/270 degrees to maintain visibility
      // and prevent image from overflowing container in different aspect ratios
      'w-[calc(100dvh-8rem)] h-[calc(100dvw-7rem)]':
        activeImageRotation % 180 !== 0,
      'size-full': activeImageRotation % 180 === 0,
    }"
  >
    <img
      ref="imageRef"
      :key="attachment.message_id"
      :src="attachment.data_url"
      :style="imageStyle"
      class="max-h-full max-w-full object-contain duration-100 ease-in-out transform select-none"
      @click.stop
      @dblclick.stop="onDoubleClickZoomImage"
      @wheel.prevent.stop="onWheelImageZoom"
      @mousemove="onMouseMove"
      @mouseleave="onMouseLeave"
    />
  </div>
</template>
