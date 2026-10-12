<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import WhatsAppInteractivePreview from 'dashboard/components-next/whatsapp/WhatsAppInteractivePreview.vue';
import { useMessageContext } from '../provider.js';

const { content, contentAttributes, attachments } = useMessageContext();

const interactive = computed(
  () => contentAttributes.value?.whatsappInteractive ?? {}
);
const body = computed(() => interactive.value.body?.text || content.value);
const buttons = computed(() => interactive.value.action?.buttons ?? []);
const attachment = computed(() => {
  const media = attachments?.value?.find(
    item => item.id === interactive.value.header?.attachmentId
  );
  if (!media) return null;
  return {
    ...media,
    name: decodeURI(media.dataUrl?.split('?')[0].split('/').pop() || ''),
  };
});
</script>

<template>
  <BaseBubble
    class="px-4 py-3 min-w-64 max-w-lg"
    data-bubble-name="whatsapp-interactive"
  >
    <WhatsAppInteractivePreview
      :body="body"
      :header="interactive.header"
      :attachment="attachment"
      :footer="interactive.footer?.text"
      :buttons="buttons"
    />
  </BaseBubble>
</template>
