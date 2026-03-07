<script setup>
import { computed } from 'vue';
import { useMessageContext } from '../../provider.js';

import MessageFormatter from 'shared/helpers/MessageFormatter.js';
import { MESSAGE_VARIANTS } from '../../constants';

const props = defineProps({
  content: {
    type: String,
    required: true,
  },
});

const { variant, contentAttributes } = useMessageContext();

const isPlainText = computed(
  () => contentAttributes.value?.format === 'plain_text'
);

const formattedContent = computed(() => {
  if (isPlainText.value) {
    return props.content;
  }

  if (variant.value === MESSAGE_VARIANTS.ACTIVITY) {
    return props.content;
  }

  return new MessageFormatter(props.content).formattedMessage;
});
</script>

<template>
  <span
    v-if="isPlainText"
    class="prose prose-bubble whitespace-pre-wrap break-words"
  >
    {{ formattedContent }}
  </span>
  <span v-else v-dompurify-html="formattedContent" class="prose prose-bubble" />
</template>
