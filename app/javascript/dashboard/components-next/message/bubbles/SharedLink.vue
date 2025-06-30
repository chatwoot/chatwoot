<script setup>
import { computed } from 'vue';
import { useMessageContext } from '../provider.js';
import BaseBubble from 'next/message/bubbles/Base.vue';

const { attachments } = useMessageContext();

const attachment = computed(() => {
  return attachments.value[0];
});

const linkDomain = computed(() => {
  return attachment.value.dataUrl
    ? new URL(attachment.value.dataUrl).hostname
    : '';
});

const domainIconUrl = computed(() => {
  return `https://www.google.com/s2/favicons?domain=${linkDomain.value}&sz=64`;
});
</script>

<template>
  <BaseBubble class="p-3 overflow-hidden" data-bubble-name="ig-story">
    <a
      v-if="attachment.dataUrl"
      class="text-base"
      :href="attachment.dataUrl"
      target="_blank"
      rel="noopener noreferrer"
      @click.stop
    >
      <img
        v-if="attachment.meta?.thumbUrl"
        class="rounded-lg w-full mb-2"
        :src="attachment.meta?.thumbUrl"
        alt="Shared Link Image"
        loading="lazy"
        @error="attachment.meta.thumbUrl = ''"
      />
      {{ attachment.fallbackTitle || 'Shared Link' }}
    </a>
    <p v-if="attachment.meta?.description" class="text-sm mt-2 text-n-slate-11">
      {{ attachment.meta.description }}
    </p>
    <p v-if="linkDomain" class="text-sm bold">
      <img
        class="inline-block w-4 h-4 mr-1"
        :src="domainIconUrl"
        alt="Favicon"
      />
      {{ linkDomain }}
    </p>
  </BaseBubble>
</template>
