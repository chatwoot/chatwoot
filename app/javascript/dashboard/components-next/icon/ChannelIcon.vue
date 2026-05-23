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
      class="absolute top-0 ltr:right-0 rtl:left-0 inline-flex items-center justify-center size-2 rounded-full bg-n-surface-1"
    >
      <Icon icon="i-lucide-audio-lines" class="size-1.5 text-n-slate-12" />
    </span>
  </span>
</template>
