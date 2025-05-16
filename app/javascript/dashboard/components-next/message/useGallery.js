import { computed } from 'vue';
import { useToggle } from '@vueuse/core';

export function useGallery() {
  const [showGallery] = useToggle(false);

  const isGalleryAllowed = computed(() => {
    // eslint-disable-next-line no-underscore-dangle
    return !window.__WOOT_ISOLATED_SHELL__;
  });

  const toggleGallery = value => {
    if (!isGalleryAllowed.value) return;

    showGallery.value = value;
  };

  return {
    showGallery,
    isGalleryAllowed,
    toggleGallery,
  };
}
