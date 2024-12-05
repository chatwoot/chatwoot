<script setup>
import { computed, onMounted, nextTick } from 'vue';
import BaseBubble from './Base.vue';
import Icon from 'next/icon/Icon.vue';
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
});

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

const setupMap = async () => {
  await nextTick();
  const map = new maplibregl.Map({
    style: 'https://tiles.openfreemap.org/styles/liberty',
    center: [long.value, lat.value],
    zoom: 9.5,
    container: 'map',
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

onMounted(setupMap);
</script>

<template>
  <BaseBubble
    class="overflow-hidden relative group outline outline-1 outline-n-weak"
  >
    <div id="map" class="max-w-md min-w-64 w-full h-36" />
    <div
      class="flex gap-2 p-2 items-center text-xs justify-between bg-n-alpha-3"
    >
      <div class="flex gap-1 items-center truncate">
        <Icon icon="i-lucide-map-pin" class="text-n-slate-10 flex-shrink-0" />
        {{ title }}
      </div>
      <a
        :href="mapUrl"
        target="blank"
        class="text-n-slate-12 flex-shrink-0 text-xs"
      >
        {{ $t('COMPONENTS.LOCATION_BUBBLE.SEE_ON_MAP') }}
      </a>
    </div>
  </BaseBubble>
</template>

<style>
@import 'maplibre-gl/dist/maplibre-gl.css';
</style>
