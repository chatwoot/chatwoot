import { ref, computed, nextTick, onMounted } from 'vue';
import { useToggle, useResizeObserver } from '@vueuse/core';

/**
 * Composable for handling expandable content with "Read more / Read less" functionality.
 * Detects content overflow and provides toggle state for expansion.
 *
 * @param {Object} options - Configuration options
 * @param {number} [options.maxLines=2] - Maximum number of lines before showing toggle
 * @param {number} [options.defaultLineHeight=20] - Fallback line height if computed style is unavailable
 * @param {boolean} [options.useResizeObserverForCheck=false] - Use ResizeObserver for continuous overflow checking
 * @returns {Object} - Composable state and methods
 */
export function useExpandableContent(options = {}) {
  const {
    maxLines = 2,
    defaultLineHeight = 20,
    useResizeObserverForCheck = false,
  } = options;

  const contentElement = ref(null);
  const [isExpanded, toggleExpanded] = useToggle(false);
  const needsToggle = ref(false);

  const showReadMore = computed(() => needsToggle.value && !isExpanded.value);
  const showReadLess = computed(() => needsToggle.value && isExpanded.value);

  /**
   * Checks if content overflows the maximum allowed height
   * and updates needsToggle accordingly
   */
  const checkOverflow = () => {
    if (!contentElement.value) return;

    const element = contentElement.value;
    const computedStyle = window.getComputedStyle(element);
    const lineHeight =
      parseFloat(computedStyle.lineHeight) || defaultLineHeight;
    const maxHeight = lineHeight * maxLines;

    needsToggle.value = element.scrollHeight > maxHeight;
  };

  // Setup overflow checking based on configuration
  if (useResizeObserverForCheck) {
    useResizeObserver(contentElement, checkOverflow);
  } else {
    onMounted(() => {
      nextTick(checkOverflow);
    });
  }

  return {
    contentElement,
    isExpanded,
    needsToggle,
    showReadMore,
    showReadLess,
    toggleExpanded,
    checkOverflow,
  };
}
