<script setup>
import { computed, ref, watch, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import BaseBubble from './Base.vue';
import Icon from 'next/icon/Icon.vue';
import { useMessageContext } from '../provider.js';

const { contentAttributes, attachments } = useMessageContext();
const { t } = useI18n();

const stickerUrl = computed(() => {
  const attachment = attachments.value?.[0];
  const url =
    contentAttributes.value?.stickerUrl ||
    contentAttributes.value?.sticker_url ||
    attachment?.dataUrl ||
    attachment?.data_url ||
    attachment?.downloadUrl ||
    attachment?.download_url ||
    attachment?.thumbUrl ||
    attachment?.thumb_url ||
    '';
  return url;
});

const retryDelays = [500, 1000, 2000, 4000, 8000, 16000, 32000, 64000];
const hasError = ref(false);
const cacheBust = ref(0);
const retryCount = ref(0);
let retryTimer;

const clearRetryTimer = () => {
  if (retryTimer) {
    clearTimeout(retryTimer);
    retryTimer = null;
  }
};

const resetRetryState = () => {
  clearRetryTimer();
  hasError.value = false;
  retryCount.value = 0;
};

const stickerSrc = computed(() => {
  const url = stickerUrl.value;
  if (!url) return '';
  if (!cacheBust.value) return url;
  const separator = url.includes('?') ? '&' : '?';
  return `${url}${separator}t=${cacheBust.value}`;
});

const handleError = () => {
  const hasMoreRetries = retryCount.value < retryDelays.length;
  const hasValidUrl = !!stickerUrl.value;

  if (!hasMoreRetries || !hasValidUrl) {
    hasError.value = true;
    return;
  }

  const delay = retryDelays[retryCount.value];
  retryCount.value += 1;

  clearRetryTimer();
  retryTimer = setTimeout(() => {
    cacheBust.value = Date.now();
  }, delay);
};

const handleLoad = () => {
  hasError.value = false;
};

watch(
  () => stickerUrl.value,
  () => {
    resetRetryState();
    cacheBust.value = Date.now();
  }
);

onBeforeUnmount(clearRetryTimer);
</script>

<template>
  <BaseBubble class="overflow-hidden p-3" data-bubble-name="sticker">
    <div v-if="hasError" class="flex items-center gap-1 text-center rounded-lg">
      <Icon icon="i-lucide-circle-off" class="text-n-slate-11" />
      <p class="mb-0 text-n-slate-11">
        {{ $t('COMPONENTS.MEDIA.IMAGE_UNAVAILABLE') }}
      </p>
    </div>
    <img
      v-else-if="stickerSrc"
      :src="stickerSrc"
      :alt="t('CONVERSATION.REPLYBOX.STICKERS.ALT')"
      class="skip-context-menu w-36 h-36 object-contain"
      @load="handleLoad"
      @error="handleError"
    />
  </BaseBubble>
</template>
