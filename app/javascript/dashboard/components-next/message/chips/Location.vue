<script setup>
import { computed } from 'vue';

const props = defineProps({
  attachment: {
    type: Object,
    required: true,
    validator: attachment => {
      return (
        attachment &&
        attachment.fileType === 'location' &&
        // Check for metadata object and coordinates within it
        attachment.metadata &&
        attachment.metadata.coordinatesLat &&
        attachment.metadata.coordinatesLong &&
        attachment.dataUrl
      );
    },
  },
});

// Extract data from metadata
const lat = computed(() => props.attachment?.metadata?.coordinatesLat);
const long = computed(() => props.attachment?.metadata?.coordinatesLong);
const locationName = computed(() => props.attachment?.metadata?.name);
const locationAddress = computed(() => props.attachment?.metadata?.address);

// Construct title from metadata name/address or fallback
const displayTitle = computed(() => {
  let title = locationName.value || props.attachment?.fallback_title || 'Location';
  if (locationAddress.value) {
    title += ` (${locationAddress.value})`;
  }
  return title;
});

const mapUrl = computed(() => {
  if (!lat.value || !long.value) {
    // Fallback to dataUrl if coordinates are missing in metadata
    return props.attachment?.dataUrl || null;
  }

  // Simple OSM embed using marker parameter
  const zoom = 50; // Adjust zoom level as needed (increased from 16)
  return `https://www.openstreetmap.org/export/embed.html?layer=mapnik&marker=${lat.value},${long.value}&zoom=${zoom}`;
});

// Determine if we should render the iframe or just the link
const renderIframe = computed(() => {
  // Render iframe if mapUrl is an OSM embed URL
  return mapUrl.value && mapUrl.value.startsWith('https://www.openstreetmap.org/export/embed.html');
});

</script>

<template>
  <div class="location-chip w-full max-w-xs p-2 border border-n-container rounded-lg bg-n-slate-3 dark:bg-n-slate-9">
    <p v-if="displayTitle" class="text-sm font-medium mb-1">
      {{ displayTitle }}
    </p>
    <div v-if="renderIframe" class="aspect-video overflow-hidden rounded">
      <iframe
        width="100%"
        height="100%"
        style="border:0"
        loading="lazy"
        allowfullscreen
        referrerpolicy="no-referrer-when-downgrade"
        :src="mapUrl"
       />
    </div>
     <a
        v-else
        :href="attachment.dataUrl"
        target="_blank"
        rel="noopener noreferrer"
        class="text-link inline-flex items-center gap-1 text-sm break-words"
      >
        <span class="i-lucide-map-pin size-3.5"></span>
        {{ displayTitle || 'View Location' }}
      </a>
  </div>
</template>

<style scoped>
.location-chip iframe {
  display: block;
}
</style> 