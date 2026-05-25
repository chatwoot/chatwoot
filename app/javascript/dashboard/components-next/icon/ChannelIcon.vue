<script setup>
import { computed, toRef } from 'vue';
import { isVoiceCallEnabled } from 'dashboard/helper/inbox';
import { useChannelIcon, useChannelImage } from './provider';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
  // When true, render the brand image (when available for the channel type)
  // and fall back to the monochrome icon otherwise.
  useImage: {
    type: Boolean,
    default: false,
  },
});

defineOptions({ inheritAttrs: false });

const inboxRef = toRef(props, 'inbox');

const hasVoiceBadge = computed(() => isVoiceCallEnabled(props.inbox));
const channelIcon = useChannelIcon(inboxRef);
const channelImage = useChannelImage(inboxRef);

const showImage = computed(() => props.useImage && channelImage.value);
</script>

<template>
  <span class="relative inline-flex" v-bind="$attrs">
    <img
      v-if="showImage"
      :src="channelImage"
      :alt="inbox.name || ''"
      class="object-contain"
    />
    <Icon v-else :icon="channelIcon" class="size-full" />
    <span
      v-if="hasVoiceBadge"
      class="absolute top-0 ltr:right-0 rtl:left-0 inline-flex items-center justify-center size-2 rounded-full bg-n-surface-1"
    >
      <Icon icon="i-lucide-audio-lines" class="size-1.5 text-n-slate-12" />
    </span>
  </span>
</template>
