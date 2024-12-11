<script setup>
import { computed } from 'vue';
import { MESSAGE_STATUS } from '../../constants';

const props = defineProps({
  contentAttributes: {
    type: Object,
    default: () => ({}),
  },
  status: {
    type: String,
    required: true,
    validator: value => Object.values(MESSAGE_STATUS).includes(value),
  },
  sender: {
    type: Object,
    default: () => ({}),
  },
});

const hasError = computed(() => {
  return props.status === MESSAGE_STATUS.FAILED;
});

const fromEmail = computed(() => {
  return props.contentAttributes?.email?.from ?? [];
});

const toEmail = computed(() => {
  return props.contentAttributes?.email?.to ?? [];
});

const ccEmail = computed(() => {
  return (
    props.contentAttributes?.ccEmails ??
    props.contentAttributes?.email?.cc ??
    []
  );
});

const senderName = computed(() => {
  return props.sender.name ?? '';
});

const bccEmail = computed(() => {
  return (
    props.contentAttributes?.bccEmails ??
    props.contentAttributes?.email?.bcc ??
    []
  );
});

const subject = computed(() => {
  return props.contentAttributes?.email?.subject ?? '';
});

const showMeta = computed(() => {
  return (
    fromEmail.value[0] ||
    toEmail.value.length ||
    ccEmail.value.length ||
    bccEmail.value.length ||
    subject.value
  );
});
</script>

<template>
  <section
    v-show="showMeta"
    class="p-4 space-y-1 pr-9 border-b border-n-strong"
    :class="hasError ? 'text-n-ruby-11' : 'text-n-slate-11'"
  >
    <template v-if="showMeta">
      <div v-if="fromEmail[0]">
        <span :class="hasError ? 'text-n-ruby-11' : 'text-n-slate-12'">
          {{ senderName }}
        </span>
        &lt;{{ fromEmail[0] }}&gt;
      </div>
      <div v-if="toEmail.length">
        {{ $t('EMAIL_HEADER.TO') }}: {{ toEmail.join(', ') }}
      </div>
      <div v-if="ccEmail.length">
        {{ $t('EMAIL_HEADER.CC') }}:
        {{ ccEmail.join(', ') }}
      </div>
      <div v-if="bccEmail.length">
        {{ $t('EMAIL_HEADER.BCC') }}:
        {{ bccEmail.join(', ') }}
      </div>
      <div v-if="subject">
        {{ $t('EMAIL_HEADER.SUBJECT') }}:
        {{ subject }}
      </div>
    </template>
  </section>
</template>
