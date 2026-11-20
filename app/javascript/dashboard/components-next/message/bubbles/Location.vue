<script setup>
import { computed } from 'vue';
import BaseAttachmentBubble from './BaseAttachment.vue';
import { useI18n } from 'vue-i18n';
import { useMessageContext } from '../provider.js';

const { attachments, contentAttributes } = useMessageContext();
const { t } = useI18n();

const attachment = computed(() => attachments.value?.[0]);
const sentLocation = computed(() => contentAttributes.value?.whatsappLocation);

const lat = computed(
  () => attachment.value?.coordinatesLat ?? sentLocation.value?.latitude
);
const long = computed(
  () => attachment.value?.coordinatesLong ?? sentLocation.value?.longitude
);

const title = computed(() => {
  if (attachment.value) {
    return attachment.value.fallbackTitle ?? attachment.value.fallback_title;
  }
  const { name, address } = sentLocation.value;
  if (!name) return t('WHATSAPP_LOCATIONS.CURRENT_LOCATION');
  return `${name}, ${address}`;
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
