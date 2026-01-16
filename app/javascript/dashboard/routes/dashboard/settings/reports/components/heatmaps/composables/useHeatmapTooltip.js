import { ref } from 'vue';

export function useHeatmapTooltip() {
  const visible = ref(false);
  const x = ref(0);
  const y = ref(0);
  const value = ref(null);

  let timeoutId = null;

  const show = (event, cellValue) => {
    clearTimeout(timeoutId);

    // Update position immediately for smooth movement
    const rect = event.target.getBoundingClientRect();
    x.value = rect.left + rect.width / 2;
    y.value = rect.top;

    // Only delay content update and visibility
    timeoutId = setTimeout(() => {
      value.value = cellValue;
      visible.value = true;
    }, 100);
  };

  const hide = () => {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => {
      visible.value = false;
    }, 50);
  };

  return { visible, x, y, value, show, hide };
}
