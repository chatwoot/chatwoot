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
const findAttachment = attachmentId => {
  if (attachmentId === undefined || attachmentId === null) return null;

  const media = attachments?.value?.find(
    item => String(item.id) === String(attachmentId)
  );
  if (!media) return null;

  return {
    ...media,
    name: decodeURI(media.dataUrl?.split('?')[0].split('/').pop() || ''),
  };
};
const attachment = computed(() => {
  const header = interactive.value.header;
  return findAttachment(header?.attachmentId ?? header?.attachment_id);
});
const cards = computed(() => {
  return (interactive.value.action?.cards ?? []).map(card => {
    const header = card.header;
    return {
      ...card,
      body: card.body?.text ?? '',
      media: findAttachment(header?.attachmentId ?? header?.attachment_id),
    };
  });
});
const actionMode = computed(() => {
  const cardType = cards.value[0]?.type;
  if (cardType === 'cta_url') return 'url';
  if (cardType === 'button') return 'quick_reply';
  return '';
});
</script>

<template>
  <BaseBubble
    class="px-4 py-3 min-w-64 max-w-lg"
    data-bubble-name="whatsapp-interactive"
  >
    <WhatsAppInteractivePreview
      :type="interactive.type"
      :body="body"
      :header="interactive.header"
      :attachment="attachment"
      :footer="interactive.footer?.text"
      :buttons="buttons"
      :opener="interactive.action?.button"
      :url="interactive.action?.url"
      :sections="interactive.action?.sections"
      :cards="cards"
      :action-mode="actionMode"
    />
  </BaseBubble>
</template>
