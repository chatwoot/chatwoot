<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { useExpandableContent } from 'shared/composables/useExpandableContent';

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

const { contentElement, showReadMore, showReadLess, toggleExpanded } =
  useExpandableContent();

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
  const wroteText = t('SEARCH.WROTE');
  return author ? `${author} ${wroteText} ` : '';
});
</script>

<template>
  <div
    ref="contentElement"
    class="break-words grid items-center text-n-slate-11 text-sm leading-relaxed"
    :class="showReadMore ? 'grid-cols-[1fr_auto]' : 'grid-cols-1'"
  >
    <div
      class="min-w-0"
      :class="{
        'overflow-hidden whitespace-nowrap text-ellipsis': showReadMore,
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
        v-if="showReadLess"
        class="text-sm text-n-slate-11 underline cursor-pointer bg-transparent border-0 p-0 hover:text-n-slate-12 font-medium ltr:ml-0.5 rtl:mr-0.5"
        @click.prevent="toggleExpanded(false)"
      >
        {{ t('SEARCH.READ_LESS') }}
      </button>
    </div>
    <button
      v-if="showReadMore"
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
