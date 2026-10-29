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
if (!subject.value) subject.value = defaultSubject.value;

const showCc = ref(false);
const showBcc = ref(false);
const ccEmailsVal = ref(ccEmails.value);
const bccEmailsVal = ref(bccEmails.value);
const toEmailsVal = ref(toEmails.value);

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

// The field follows the default only until the agent edits it
watch(defaultSubject, (value, previousValue) => {
  if (subject.value === previousValue) subject.value = value;
});

const onBlur = () => {
  v$.value.$touch();
  ccEmails.value = ccEmailsVal.value;
  bccEmails.value = bccEmailsVal.value;
  toEmails.value = toEmailsVal.value;
};
</script>

<template>
  <div>
    <div>
      <div
        class="flex items-center gap-2 my-1 border-b border-solid input-group small"
        :class="
          v$.toEmailsVal.$error ? 'error border-n-ruby-8' : 'border-n-weak'
        "
      >
        <label
          class="text-sm font-normal"
          :class="v$.toEmailsVal.$error ? 'text-n-ruby-8' : 'text-n-slate-11'"
        >
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
    <div v-if="isCcVisible">
      <div
        class="flex items-center gap-2 my-1 border-b border-solid input-group small"
        :class="
          v$.ccEmailsVal.$error ? 'error border-n-ruby-8' : 'border-n-weak'
        "
      >
        <label
          class="text-sm font-normal"
          :class="v$.ccEmailsVal.$error ? 'text-n-ruby-8' : 'text-n-slate-11'"
        >
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
      <span v-if="v$.ccEmailsVal.$error" class="text-sm text-n-ruby-8">
        {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.CC.ERROR') }}
      </span>
    </div>
    <div v-if="isBccVisible">
      <div
        class="flex items-center gap-2 my-1 border-b border-solid input-group small"
        :class="
          v$.bccEmailsVal.$error ? 'error border-n-ruby-8' : 'border-n-weak'
        "
      >
        <label
          class="text-sm font-normal"
          :class="v$.bccEmailsVal.$error ? 'text-n-ruby-8' : 'text-n-slate-11'"
        >
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
      <span v-if="v$.bccEmailsVal.$error" class="text-sm text-n-ruby-8">
        {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.BCC.ERROR') }}
      </span>
    </div>
    <div
      class="flex items-center gap-2 my-1 border-b border-solid border-n-weak input-group small"
    >
      <label class="text-sm font-normal text-n-slate-11">
        {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.SUBJECT.LABEL') }}
      </label>
      <div class="flex-1 min-w-0 m-0 rounded-none whitespace-nowrap">
        <woot-input
          v-model="subject"
          type="text"
          class="[&>input]:!mb-0 [&>input]:border-transparent [&>input]:!outline-none [&>input]:h-8 [&>input]:!text-sm [&>input]:!border-0 [&>input]:border-none [&>input]:!bg-transparent dark:[&>input]:!bg-transparent"
          :placeholder="
            $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.SUBJECT.PLACEHOLDER')
          "
        />
      </div>
    </div>
  </div>
</template>
