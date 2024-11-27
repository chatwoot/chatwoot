<script setup>
import { computed } from 'vue';
import MessageFormatter from 'shared/helpers/MessageFormatter.js';
import BaseBubble from './Base.vue';
import { useMessageContext } from '../provider.js';
import { MESSAGE_VARIANTS } from '../constants';

const props = defineProps({
  content: {
    type: String,
    required: true,
  },
});

const { variant } = useMessageContext();

const formattedContent = computed(() => {
  if (variant.value === MESSAGE_VARIANTS.ACTIVITY) {
    return props.content;
  }

  return new MessageFormatter(props.content).formattedMessage;
});
</script>

<template>
  <BaseBubble>
    <span v-html="formattedContent" />
  </BaseBubble>
</template>

<style>
p:last-child {
  margin-bottom: 0;
}
</style>
