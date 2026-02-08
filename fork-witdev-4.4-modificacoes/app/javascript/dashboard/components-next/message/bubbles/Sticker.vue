<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import BaseBubble from './Base.vue';
import Icon from 'next/icon/Icon.vue';
import { useMessageContext } from '../provider.js';

const emit = defineEmits(['error']);
const { t } = useI18n();

const { contentAttributes } = useMessageContext();

const hasError = ref(false);
const isLoading = ref(true);

const stickerData = computed(() => {
  return contentAttributes.value?.stickerData || {};
});

const stickerUrl = computed(() => {
  return stickerData.value.url || '';
});

const stickerAlt = computed(() => {
  return stickerData.value.alt || t('CONVERSATION.STICKER_ALT_TEXT');
});

const stickerProvider = computed(() => {
  return stickerData.value.provider || 'unknown';
});

const isDevelopment = computed(() => {
  return import.meta.env.MODE !== 'production';
});

const handleError = () => {
  hasError.value = true;
  isLoading.value = false;
  emit('error');
};

const handleLoad = () => {
  isLoading.value = false;
};
</script>

<template>
  <BaseBubble class="overflow-hidden p-2 max-w-xs" data-bubble-name="sticker">
    <div
      v-if="hasError"
      class="flex items-center gap-2 text-center rounded-lg p-4"
    >
      <Icon icon="i-lucide-circle-off" class="text-n-slate-11" />
      <p class="mb-0 text-n-slate-11 text-sm">
        {{ $t('CONVERSATION.STICKER_UNAVAILABLE') }}
      </p>
    </div>
    <div v-else class="relative">
      <!-- Loading state -->
      <div
        v-if="isLoading"
        class="flex items-center justify-center w-32 h-32 bg-n-slate-2 rounded-lg animate-pulse"
        :aria-label="$t('CONVERSATION.STICKER_LOADING')"
      >
        <Icon icon="i-lucide-loader-2" class="animate-spin text-n-slate-8" />
      </div>

      <!-- Sticker image -->
      <img
        v-show="!isLoading && !hasError"
        class="skip-context-menu rounded-lg max-w-32 max-h-32 w-auto h-auto"
        :src="stickerUrl"
        :alt="stickerAlt"
        :title="stickerAlt"
        :aria-label="stickerAlt"
        @load="handleLoad"
        @error="handleError"
      />

      <!-- Provider badge (optional, for debugging) -->
      <div
        v-if="!isLoading && !hasError && stickerProvider && isDevelopment"
        class="absolute top-1 right-1 bg-n-slate-12/70 text-n-slate-1 text-xs px-1 py-0.5 rounded opacity-60"
      >
        {{ stickerProvider }}
      </div>
    </div>
  </BaseBubble>
</template>

<style scoped>
/* Ensure stickers maintain aspect ratio and don't exceed container */
img {
  object-fit: contain;
}

/* Responsive behavior for different screen sizes */
@media (max-width: 640px) {
  img {
    max-width: 96px;
    max-height: 96px;
  }
}

@media (max-width: 480px) {
  img {
    max-width: 80px;
    max-height: 80px;
  }
}
</style>
