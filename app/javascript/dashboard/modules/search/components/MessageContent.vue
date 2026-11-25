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
const { getPlainText } = useMessageFormatter();

const { contentElement, showReadMore, showReadLess, toggleExpanded } =
  useExpandableContent();

const messageContent = computed(() => {
  // Voice-call messages carry a generic content label (e.g. "Twilio voice
  // call"), so a transcript match would otherwise be hidden behind it.
  if (
    props.message.contentType === 'voice_call' &&
    props.message.call?.transcript
  ) {
    return props.message.call.transcript;
  }

  // We perform search on either content, email subject, or transcribed text
  // (voice-note attachments)
  if (props.message.content) {
    return props.message.content;
  }

  const { email = {} } = props.message.contentAttributes || {};
  if (email.subject) {
    return email.subject;
  }

  const audioAttachment = props.message.attachments?.find(
    attachment => attachment.fileType === 'audio'
  );
  return audioAttachment?.transcribedText || '';
});

const escapeHtml = html => {
  const wrapper = document.createElement('p');
  wrapper.textContent = html;
  return wrapper.innerHTML;
};

const highlightedContent = computed(() => {
  // getPlainText decodes any markdown in the source into literal text (e.g. a
  // literal "<img ...>" in the transcript stays as visible characters rather
  // than a tag). escapeHtml then HTML-encodes that text so the highlight
  // <span> injected below is the only real markup in the final string passed
  // to v-dompurify-html.
  const plainText = getPlainText(messageContent.value || '');
  const escapedText = escapeHtml(plainText);

  const searchTerm = props.searchTerm || '';
  if (!searchTerm) {
    return escapedText;
  }

  const escapedSearchTerm = escapeHtml(searchTerm).replace(
    /[.*+?^${}()|[\]\\]/g,
    '\\$&'
  );
  return escapedText.replace(
    new RegExp(`(${escapedSearchTerm})`, 'ig'),
    '<span class="searchkey--highlight">$1</span>'
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
.message-content :deep(p) {
  @apply inline;
  margin: 0;
}

.message-content :deep(br) {
  display: none;
}
</style>
