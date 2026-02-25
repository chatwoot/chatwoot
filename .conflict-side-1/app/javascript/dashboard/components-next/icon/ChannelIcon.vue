<script setup>
import { toRef } from 'vue';
import { useChannelIcon } from './provider';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

const channelIcon = useChannelIcon(toRef(props, 'inbox'));
</script>

<template>
  <Icon :icon="channelIcon" />
</template>
