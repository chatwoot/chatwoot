<script setup>
import { computed, onMounted, nextTick, useTemplateRef } from 'vue';
import BaseAttachmentBubble from './BaseAttachment.vue';
import { useI18n } from 'vue-i18n';
import maplibregl from 'maplibre-gl';

/**
 * @typedef {Object} Attachment
 * @property {number} id - Unique identifier for the attachment
 * @property {number} messageId - ID of the associated message
 * @property {'image'|'audio'|'video'|'file'|'location'|'fallback'|'share'|'story_mention'|'contact'|'ig_reel'} fileType - Type of the attachment (file or image)
 * @property {number} accountId - ID of the associated account
 * @property {string|null} extension - File extension
 * @property {string} dataUrl - URL to access the full attachment data
 * @property {string} thumbUrl - URL to access the thumbnail version
 * @property {number} fileSize - Size of the file in bytes
 * @property {number|null} width - Width of the image if applicable
 * @property {number|null} height - Height of the image if applicable
 */

/**
 * @typedef {Object} Props
 * @property {Attachment[]} [attachments=[]] - The attachments associated with the message
 */

const props = defineProps({
  attachments: {
    type: Array,
    required: true,
  },
  sender: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();

const attachment = computed(() => {
  return props.attachments[0];
});

const lat = computed(() => {
  return attachment.value.coordinatesLat;
});
const long = computed(() => {
  return attachment.value.coordinatesLong;
});

const title = computed(() => {
  return attachment.value.fallbackTitle;
});

const mapUrl = computed(
  () => `https://maps.google.com/?q=${lat.value},${long.value}`
);

const mapContainer = useTemplateRef('mapContainer');

const setupMap = () => {
  const map = new maplibregl.Map({
    style: 'https://tiles.openfreemap.org/styles/positron',
    center: [long.value, lat.value],
    zoom: 9.5,
    container: mapContainer.value,
    attributionControl: false,
    dragPan: false,
    dragRotate: false,
    scrollZoom: false,
    touchZoom: false,
    touchRotate: false,
    keyboard: false,
    doubleClickZoom: false,
  });

  return map;
};

onMounted(async () => {
  await nextTick();
  setupMap();
});
</script>

<template>
  <BaseAttachmentBubble
    icon="i-ph-navigation-arrow-fill"
    icon-bg-color="bg-[#0D9B8A]"
    :sender="sender"
    sender-translation-key="CONVERSATION.SHARED_ATTACHMENT.LOCATION"
    :content="title"
    :action="{
      label: t('COMPONENTS.LOCATION_BUBBLE.SEE_ON_MAP'),
      href: mapUrl,
    }"
  >
    <template #before>
      <div
        ref="mapContainer"
        class="z-10 w-full max-w-md -mb-12 min-w-64 h-28"
      />
    </template>
  </BaseAttachmentBubble>
</template>

<style>
@import 'maplibre-gl/dist/maplibre-gl.css';
</style>
