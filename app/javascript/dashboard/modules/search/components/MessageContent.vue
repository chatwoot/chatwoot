<script setup>
import { ref, useTemplateRef, onMounted, watch, nextTick } from 'vue';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import ReadMore from './ReadMore.vue';

const props = defineProps({
  author: {
    type: String,
    default: '',
  },
  content: {
    type: String,
    default: '',
  },
  searchTerm: {
    type: String,
    default: '',
  },
});

const { highlightContent } = useMessageFormatter();

const messageContainer = useTemplateRef('messageContainer');
const isOverflowing = ref(false);

const setOverflow = () => {
  const wrap = messageContainer.value;
  if (wrap) {
    const message = wrap.querySelector('.message-content');
    isOverflowing.value = message.offsetHeight > 150;
  }
};

const escapeHtml = html => {
  var text = document.createTextNode(html);
  var p = document.createElement('p');
  p.appendChild(text);
  return p.innerText;
};

const prepareContent = (content = '') => {
  const escapedText = escapeHtml(content);
  return highlightContent(
    escapedText,
    props.searchTerm,
    'searchkey--highlight'
  );
};

onMounted(() => {
  watch(() => {
    return messageContainer.value;
  }, setOverflow);

  nextTick(setOverflow);
});
</script>

<template>
  <blockquote ref="messageContainer" class="message border-l-2 border-n-weak">
    <p class="header">
      <strong class="text-n-slate-11">
        {{ author }}
      </strong>
      {{ $t('SEARCH.WROTE') }}
    </p>
    <ReadMore :shrink="isOverflowing" @expand="isOverflowing = false">
      <div v-dompurify-html="prepareContent(content)" class="message-content" />
    </ReadMore>
  </blockquote>
</template>

<style scoped lang="scss">
.message {
  @apply py-0 px-2 mt-2;
}
.message-content::v-deep p,
.message-content::v-deep li::marker {
  @apply text-n-slate-11 mb-1;
}

.header {
  @apply text-n-slate-11 mb-1;
}

.message-content {
  @apply break-words text-n-slate-11;
}

.message-content::v-deep .searchkey--highlight {
  @apply text-n-slate-12 text-sm font-semibold;
}
</style>
