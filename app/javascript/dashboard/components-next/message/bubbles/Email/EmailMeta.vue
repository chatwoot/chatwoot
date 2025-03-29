<script setup>
import { computed } from 'vue';
import { MESSAGE_STATUS } from '../../constants';
import { useMessageContext } from '../../provider.js';

const { contentAttributes, status, sender } = useMessageContext();

const hasError = computed(() => {
  return status.value === MESSAGE_STATUS.FAILED;
});

const fromEmail = computed(() => {
  return contentAttributes.value?.email?.from ?? [];
});

const toEmail = computed(() => {
  return contentAttributes.value?.email?.to ?? [];
});

const ccEmail = computed(() => {
  return (
    contentAttributes.value?.ccEmails ??
    contentAttributes.value?.email?.cc ??
    []
  );
});

const senderName = computed(() => {
  const fromEmailAddress = fromEmail.value[0] ?? '';
  const senderEmail = sender.value.email ?? '';

  if (!fromEmailAddress && !senderEmail) return null;

  // if the sender of the conversation and the sender of this particular
  // email are the same, only then we return the sender name
  if (fromEmailAddress === senderEmail) {
    return sender.value.name;
  }

  return null;
});

const bccEmail = computed(() => {
  return (
    contentAttributes.value?.bccEmails ??
    contentAttributes.value?.email?.bcc ??
    []
  );
});

const subject = computed(() => {
  return contentAttributes.value?.email?.subject ?? '';
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
    class="space-y-1 rtl:pl-9 ltr:pr-9 text-sm break-words"
    :class="hasError ? 'text-n-ruby-11' : 'text-n-slate-11'"
  >
    <template v-if="showMeta">
      <div
        v-if="fromEmail[0]"
        :class="hasError ? 'text-n-ruby-11' : 'text-n-slate-12'"
      >
        <template v-if="senderName">
          <span>
            {{ senderName }}
          </span>
          &lt;{{ fromEmail[0] }}&gt;
        </template>
        <template v-else>
          {{ fromEmail[0] }}
        </template>
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
