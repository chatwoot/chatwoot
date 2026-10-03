<script setup>
import { computed, ref, watch } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { useMapGetter } from 'dashboard/composables/store';
import {
  validEmailsByComma,
  getDefaultSubject,
} from './helpers/emailHeadHelper';
import ButtonV4 from 'dashboard/components-next/button/Button.vue';

const ccEmails = defineModel('ccEmails', { type: String, default: '' });
const bccEmails = defineModel('bccEmails', { type: String, default: '' });
const toEmails = defineModel('toEmails', { type: String, default: '' });
const subject = defineModel('subject', { type: String, default: '' });

const currentChat = useMapGetter('getSelectedChat');
const defaultSubject = computed(() => getDefaultSubject(currentChat.value));

const showCc = ref(false);
const showBcc = ref(false);
const ccEmailsVal = ref(ccEmails.value);
const bccEmailsVal = ref(bccEmails.value);
const toEmailsVal = ref(toEmails.value);
const subjectVal = ref(subject.value || defaultSubject.value);

const isCcVisible = computed(() => showCc.value || !!ccEmails.value);
const isBccVisible = computed(() => showBcc.value || !!bccEmails.value);

const emailRules = { hasValidEmails: validEmailsByComma };
const v$ = useVuelidate(
  {
    ccEmailsVal: emailRules,
    bccEmailsVal: emailRules,
    toEmailsVal: emailRules,
  },
  { ccEmailsVal, bccEmailsVal, toEmailsVal }
);

watch(ccEmails, value => {
  ccEmailsVal.value = value;
});

watch(bccEmails, value => {
  bccEmailsVal.value = value;
});

watch(toEmails, value => {
  toEmailsVal.value = value;
});

watch(defaultSubject, value => {
  subjectVal.value = value;
});

watch(
  () => currentChat.value.id,
  () => {
    showCc.value = false;
    showBcc.value = false;
    subjectVal.value = defaultSubject.value;
    subject.value = '';
  }
);

const onBlur = () => {
  v$.value.$touch();
  ccEmails.value = ccEmailsVal.value;
  bccEmails.value = bccEmailsVal.value;
  toEmails.value = toEmailsVal.value;

  const trimmedSubject = subjectVal.value.trim();
  subject.value = trimmedSubject === defaultSubject.value ? '' : trimmedSubject;
};
</script>

<template>
  <div>
    <div>
      <div class="input-group small" :class="{ error: v$.toEmailsVal.$error }">
        <label class="input-group-label">
          {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.TO') }}
        </label>
        <div class="flex-1 min-w-0 m-0 rounded-none whitespace-nowrap">
          <woot-input
            v-model="v$.toEmailsVal.$model"
            type="text"
            class="[&>input]:!mb-0 [&>input]:border-transparent [&>input]:!outline-none [&>input]:h-8 [&>input]:!text-sm [&>input]:!border-0 [&>input]:border-none [&>input]:!bg-transparent dark:[&>input]:!bg-transparent"
            :class="{ error: v$.toEmailsVal.$error }"
            :placeholder="$t('CONVERSATION.REPLYBOX.EMAIL_HEAD.CC.PLACEHOLDER')"
            @blur="onBlur"
          />
        </div>
        <ButtonV4
          v-if="!isCcVisible && !isBccVisible"
          :label="$t('CONVERSATION.REPLYBOX.EMAIL_HEAD.CC.LABEL')"
          link
          xs
          @click="showCc = true"
        />
        <ButtonV4
          v-if="!isCcVisible && !isBccVisible"
          :label="$t('CONVERSATION.REPLYBOX.EMAIL_HEAD.BCC.LABEL')"
          link
          xs
          @click="showBcc = true"
        />
      </div>
    </div>
    <div v-if="isCcVisible" class="input-group-wrap">
      <div class="input-group small" :class="{ error: v$.ccEmailsVal.$error }">
        <label class="input-group-label">
          {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.CC.LABEL') }}
        </label>
        <div class="flex-1 min-w-0 m-0 rounded-none whitespace-nowrap">
          <woot-input
            v-model="v$.ccEmailsVal.$model"
            class="[&>input]:!mb-0 [&>input]:border-transparent [&>input]:!outline-none [&>input]:h-8 [&>input]:!text-sm [&>input]:!border-0 [&>input]:border-none [&>input]:!bg-transparent dark:[&>input]:!bg-transparent"
            type="text"
            :class="{ error: v$.ccEmailsVal.$error }"
            :placeholder="$t('CONVERSATION.REPLYBOX.EMAIL_HEAD.CC.PLACEHOLDER')"
            @blur="onBlur"
          />
        </div>
        <ButtonV4
          v-if="!isBccVisible"
          :label="$t('CONVERSATION.REPLYBOX.EMAIL_HEAD.BCC.LABEL')"
          link
          xs
          @click="showBcc = true"
        />
      </div>
      <span v-if="v$.ccEmailsVal.$error" class="message">
        {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.CC.ERROR') }}
      </span>
    </div>
    <div v-if="isBccVisible" class="input-group-wrap">
      <div class="input-group small" :class="{ error: v$.bccEmailsVal.$error }">
        <label class="input-group-label">
          {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.BCC.LABEL') }}
        </label>
        <div class="flex-1 min-w-0 m-0 rounded-none whitespace-nowrap">
          <woot-input
            v-model="v$.bccEmailsVal.$model"
            type="text"
            class="[&>input]:!mb-0 [&>input]:border-transparent [&>input]:!outline-none [&>input]:h-8 [&>input]:!text-sm [&>input]:!border-0 [&>input]:border-none [&>input]:!bg-transparent dark:[&>input]:!bg-transparent"
            :class="{ error: v$.bccEmailsVal.$error }"
            :placeholder="
              $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.BCC.PLACEHOLDER')
            "
            @blur="onBlur"
          />
        </div>
        <ButtonV4
          v-if="!isCcVisible"
          :label="$t('CONVERSATION.REPLYBOX.EMAIL_HEAD.CC.LABEL')"
          link
          xs
          @click="showCc = true"
        />
      </div>
      <span v-if="v$.bccEmailsVal.$error" class="message">
        {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.BCC.ERROR') }}
      </span>
    </div>
    <div class="input-group small">
      <label class="input-group-label">
        {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.SUBJECT.LABEL') }}
      </label>
      <div class="flex-1 min-w-0 m-0 rounded-none whitespace-nowrap">
        <woot-input
          v-model="subjectVal"
          type="text"
          class="[&>input]:!mb-0 [&>input]:border-transparent [&>input]:!outline-none [&>input]:h-8 [&>input]:!text-sm [&>input]:!border-0 [&>input]:border-none [&>input]:!bg-transparent dark:[&>input]:!bg-transparent"
          :placeholder="
            $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.SUBJECT.PLACEHOLDER')
          "
          @blur="onBlur"
        />
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.input-group-wrap .message {
  @apply text-sm text-n-ruby-8;
}
.input-group {
  @apply border-b border-solid border-n-weak my-1 flex items-center gap-2;

  .input-group-label {
    @apply border-transparent bg-transparent text-sm font-normal text-n-slate-11 pl-0;
  }
}

.input-group.error {
  @apply border-n-ruby-8;
  .input-group-label {
    @apply text-n-ruby-8;
  }
}
</style>
