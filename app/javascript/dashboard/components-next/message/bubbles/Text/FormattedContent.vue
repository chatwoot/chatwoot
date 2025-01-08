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

const { variant } = useMessageContext();

const formattedContent = computed(() => {
  if (variant.value === MESSAGE_VARIANTS.ACTIVITY) {
    return props.content;
  }

  return new MessageFormatter(props.content).formattedMessage;
});
</script>

<template>
  <span
    v-dompurify-html="formattedContent"
    class="[&_.link]:text-n-slate-11 [&_.link]:underline [&>p:last-child]:mb-0 [&>ul]:list-inside [&>ol]:list-inside [&>dl]:list-inside [&>ol]:list-decimal [&>ul]:list-disc [&>blockquote]:border-l-4 [&>blockquote]:border-n-alpha-black1 [&>blockquote]:pl-2"
  />
</template>
