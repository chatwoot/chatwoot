<script setup>
import { computed, toRef } from 'vue';
import { isVoiceCallEnabled } from 'dashboard/helper/inbox';
import { useChannelIcon, useChannelBrandIcon } from './provider';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
  // When true, render the full-color brand icon (when one exists for the
  // channel type) and fall back to the monochrome glyph otherwise.
  useBrandIcon: {
    type: Boolean,
    default: false,
  },
});

defineOptions({ inheritAttrs: false });

const inboxRef = toRef(props, 'inbox');

const hasVoiceBadge = computed(() => isVoiceCallEnabled(props.inbox));
const channelIcon = useChannelIcon(inboxRef);
const brandIcon = useChannelBrandIcon(inboxRef);

const icon = computed(() =>
  props.useBrandIcon && brandIcon.value ? brandIcon.value : channelIcon.value
);
</script>

<template>
  <span class="relative inline-flex" v-bind="$attrs">
    <Icon :icon="icon" class="size-full" />
    <span
      v-if="hasVoiceBadge"
      class="absolute top-0 ltr:right-0 rtl:left-0 inline-flex items-center justify-center size-2 rounded-full bg-n-surface-1"
    >
      <Icon icon="i-lucide-audio-lines" class="size-1.5 text-n-slate-12" />
    </span>
  </span>
</template>
