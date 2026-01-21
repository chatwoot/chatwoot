import { computed } from 'vue';
import { useToggle } from '@vueuse/core';

export function useGallery() {
  const [showGallery] = useToggle(false);

  const isGalleryAllowed = computed(() => {
    return true;
  });

  const toggleGallery = value => {
    showGallery.value = value;
  };

  return {
    showGallery,
    isGalleryAllowed,
    toggleGallery,
  };
}
