<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import { useMessageContext } from '../provider.js';
import { useI18n } from 'vue-i18n';

const { attachments } = useMessageContext();
const { t } = useI18n();

const attachment = computed(() => {
  return attachments.value[0];
});
</script>

<template>
  <BaseBubble class="overflow-hidden p-3" data-bubble-name="embed">
    <div
      class="w-full max-w-[360px] sm:max-w-[420px] min-h-[520px] h-[70vh] max-h-[680px]"
    >
      <iframe
        class="w-full h-full border-0 rounded-lg"
        :title="t('CHAT_LIST.ATTACHMENTS.embed.CONTENT')"
        :src="attachment.dataUrl"
        loading="lazy"
        allow="autoplay; encrypted-media; picture-in-picture"
        allowfullscreen
      />
    </div>
  </BaseBubble>
</template>
