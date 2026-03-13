import { ref, onMounted, onUnmounted } from 'vue';

export const useKeyboardResize = () => {
  const keyboardHeight = ref(0);
  const isKeyboardOpen = ref(false);

  let viewport = null;

  const onResize = () => {
    if (!viewport) return;
    const height = Math.round(window.innerHeight - viewport.height);
    keyboardHeight.value = Math.max(0, height);
    isKeyboardOpen.value = height > 50;

    if (isKeyboardOpen.value && document.activeElement) {
      requestAnimationFrame(() => {
        document.activeElement.scrollIntoView?.({
          block: 'nearest',
          behavior: 'smooth',
        });
      });
    }
  };

  onMounted(() => {
    viewport = window.visualViewport;
    if (viewport) {
      viewport.addEventListener('resize', onResize);
    }
  });

  onUnmounted(() => {
    if (viewport) {
      viewport.removeEventListener('resize', onResize);
    }
  });

  return { keyboardHeight, isKeyboardOpen };
};
