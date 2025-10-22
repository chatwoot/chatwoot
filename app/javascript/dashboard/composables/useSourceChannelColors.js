import { ref, computed } from 'vue';
import chatwootExtraAPI from '../api/chatwootExtra';

const colorCache = ref({});
const loadingInboxes = ref(new Set());

export const useSourceChannelColors = () => {
  const getSourceBgColor = async inboxId => {
    if (!inboxId) return null;

    if (colorCache.value[inboxId] !== undefined) {
      return colorCache.value[inboxId];
    }

    if (loadingInboxes.value.has(inboxId)) {
      return null;
    }

    try {
      loadingInboxes.value.add(inboxId);
      const response = await chatwootExtraAPI.getSourceChannel(inboxId);

      if (response.success && response.data) {
        const color = response.data.bgColor;
        colorCache.value = { ...colorCache.value, [inboxId]: color };
        return color;
      }
    } catch (error) {
      colorCache.value = { ...colorCache.value, [inboxId]: null };
    } finally {
      loadingInboxes.value.delete(inboxId);
    }

    return null;
  };

  const setSourceBgColor = (inboxId, color) => {
    colorCache.value = { ...colorCache.value, [inboxId]: color };
  };

  const getInboxBackgroundStyle = inboxId => {
    const color = colorCache.value[inboxId];
    if (!color) return {};

    return {
      backgroundColor: `${color}0A`,
    };
  };

  const clearCache = () => {
    colorCache.value = {};
    loadingInboxes.value.clear();
  };

  return {
    getSourceBgColor,
    setSourceBgColor,
    getInboxBackgroundStyle,
    colorCache: computed(() => colorCache.value),
    clearCache,
  };
};
