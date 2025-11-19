<script setup>
import { ref, computed, nextTick, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

const props = defineProps({
  author: {
    type: String,
    default: '',
  },
  message: {
    type: Object,
    default: () => ({}),
  },
  searchTerm: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();
const { highlightContent } = useMessageFormatter();

const contentElement = ref(null);
const [isExpanded, toggleExpanded] = useToggle(false);
const needsToggle = ref(false);

const messageContent = computed(() => {
  // We perform search on either content or email subject or transcribed text
  if (props.message.content) {
    return props.message.content;
  }

  const { content_attributes = {} } = props.message;
  const { email = {} } = content_attributes || {};
  if (email.subject) {
    return email.subject;
  }

  const audioAttachment = props.message.attachments?.find(
    attachment => attachment.file_type === 'audio'
  );
  return audioAttachment?.transcribed_text || '';
});

const escapeHtml = html => {
  const wrapper = document.createElement('p');
  wrapper.textContent = html;
  return wrapper.textContent;
};

const highlightedContent = computed(() => {
  const content = messageContent.value || '';
  const escapedText = escapeHtml(content);
  return highlightContent(
    escapedText,
    props.searchTerm,
    'searchkey--highlight'
  );
});

const authorText = computed(() => {
  const author = props.author || '';
  const wroteText = t('SEARCH.WROTE') || 'wrote:';
  return author ? `${author} ${wroteText} ` : '';
});

const checkOverflow = () => {
  if (!contentElement.value) return;

  const element = contentElement.value;
  const computedStyle = window.getComputedStyle(element);
  const lineHeight = parseFloat(computedStyle.lineHeight) || 20;
  const maxHeight = lineHeight * 2;

  needsToggle.value = element.scrollHeight > maxHeight;
};

onMounted(() => {
  nextTick(checkOverflow);
});
</script>

<template>
  <div
    ref="contentElement"
    class="break-words grid items-center text-n-slate-11 text-sm leading-relaxed"
    :class="needsToggle && !isExpanded ? 'grid-cols-[1fr_auto]' : 'grid-cols-1'"
  >
    <div
      class="min-w-0"
      :class="{
        'overflow-hidden whitespace-nowrap text-ellipsis':
          !isExpanded && needsToggle,
      }"
    >
      <span v-if="authorText" class="text-n-slate-11 font-medium leading-4">{{
        authorText
      }}</span>
      <span
        v-dompurify-html="highlightedContent"
        class="message-content text-n-slate-12 [&_.searchkey--highlight]:text-n-slate-12 [&_.searchkey--highlight]:font-semibold"
      />
      <button
        v-if="needsToggle && isExpanded"
        class="text-sm text-n-slate-11 underline cursor-pointer bg-transparent border-0 p-0 hover:text-n-slate-12 font-medium ltr:ml-0.5 rtl:mr-0.5"
        @click.prevent="toggleExpanded(false)"
      >
        {{ t('SEARCH.READ_LESS') }}
      </button>
    </div>
    <button
      v-if="needsToggle && !isExpanded"
      class="text-sm text-n-slate-11 underline cursor-pointer bg-transparent border-0 p-0 hover:text-n-slate-12 font-medium justify-self-end ltr:ml-0.5 rtl:mr-0.5"
      @click.prevent="toggleExpanded(true)"
    >
      {{ t('SEARCH.READ_MORE') }}
    </button>
  </div>
</template>

<style scoped lang="scss">
.message-content::v-deep p {
  @apply inline;
  margin: 0;
}

.message-content::v-deep br {
  display: none;
}
</style>
