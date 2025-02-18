<script setup>
import { useChannelIcon } from './provider';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

const channelIcon = useChannelIcon(props.inbox);
</script>

<template>
  <Icon :icon="channelIcon" />
</template>
