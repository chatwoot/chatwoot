<script setup>
import { computed } from 'vue';
import BaseAttachmentBubble from './BaseAttachment.vue';
import { useI18n } from 'vue-i18n';
import { useMessageContext } from '../provider.js';

const { attachments } = useMessageContext();
const { t } = useI18n();

const attachment = computed(() => {
  return attachments.value[0];
});

const lat = computed(() => {
  return attachment.value.coordinatesLat;
});
const long = computed(() => {
  return attachment.value.coordinatesLong;
});

const title = computed(() => {
  return attachment.value.fallbackTitle ?? attachment.value.fallback_title;
});

const mapUrl = computed(
  () => `https://maps.google.com/?q=${lat.value},${long.value}`
);
</script>

<template>
  <BaseAttachmentBubble
    icon="i-ph-navigation-arrow-fill"
    icon-bg-color="bg-[#0D9B8A]"
    sender-translation-key="CONVERSATION.SHARED_ATTACHMENT.LOCATION"
    :content="title"
    :action="{
      label: t('COMPONENTS.LOCATION_BUBBLE.SEE_ON_MAP'),
      href: mapUrl,
    }"
  />
</template>
