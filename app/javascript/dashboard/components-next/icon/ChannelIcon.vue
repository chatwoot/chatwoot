<script setup>
import { computed, toRef } from 'vue';
import { isVoiceCallEnabled } from 'dashboard/helper/inbox';
import { useChannelIcon } from './provider';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

defineOptions({ inheritAttrs: false });

const channelIcon = useChannelIcon(toRef(props, 'inbox'));
const hasVoiceBadge = computed(() => isVoiceCallEnabled(props.inbox));
</script>

<template>
  <span class="relative inline-flex" v-bind="$attrs">
    <Icon :icon="channelIcon" class="size-full" />
    <span
      v-if="hasVoiceBadge"
      class="absolute -top-1 ltr:-right-1 rtl:-left-1 inline-flex items-center justify-center size-2.5 rounded-full bg-n-alpha-2 ring-1 ring-n-solid-1"
    >
      <Icon icon="i-lucide-audio-lines" class="size-1.5 text-n-slate-10" />
    </span>
  </span>
</template>
