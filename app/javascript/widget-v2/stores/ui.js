import { defineStore } from 'pinia';
import { ref } from 'vue';
import { sendToHost } from 'widget-v2/helpers/bridge';

export const useUiStore = defineStore('ui', () => {
  const isOpen = ref(false);
  const widgetOpenedOnce = ref(false);

  const setOpen = open => {
    isOpen.value = open;
    if (open) widgetOpenedOnce.value = true;
  };

  const close = () => {
    sendToHost('toggleBubble');
  };

  return { isOpen, widgetOpenedOnce, setOpen, close };
});
