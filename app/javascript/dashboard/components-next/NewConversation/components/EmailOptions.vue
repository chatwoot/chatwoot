<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import TagInput from 'dashboard/components-next/taginput/TagInput.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';

const props = defineProps({
  contacts: { type: Array, required: true },
  showCcEmailsDropdown: { type: Boolean, required: false },
  showBccEmailsDropdown: { type: Boolean, required: false },
  showBccInput: { type: Boolean, default: false },
  isLoading: { type: Boolean, default: false },
  hasErrors: { type: Boolean, default: false },
});

const emit = defineEmits([
  'searchCcEmails',
  'searchBccEmails',
  'toggleBcc',
  'updateDropdown',
]);

const subject = defineModel('subject', { type: String, default: '' });
const ccEmails = defineModel('ccEmails', { type: String, default: '' });
const bccEmails = defineModel('bccEmails', { type: String, default: '' });

const { t } = useI18n();

// Convert string to array for TagInput
const ccEmailsArray = computed(() =>
  props.ccEmails ? props.ccEmails.split(',').map(email => email.trim()) : []
);

const bccEmailsArray = computed(() =>
  props.bccEmails ? props.bccEmails.split(',').map(email => email.trim()) : []
);

const contactEmailsList = computed(() => {
  return props.contacts?.map(({ name, id, email }) => ({
    id,
    label: email,
    email,
    thumbnail: { name: name, src: '' },
    value: id,
    action: 'email',
  }));
});

// Handle updates from TagInput and convert array back to string
const handleCcUpdate = value => {
  ccEmails.value = value.join(',');
};

const handleBccUpdate = value => {
  bccEmails.value = value.join(',');
};
</script>

<template>
  <div class="flex flex-col divide-y divide-n-strong">
    <div class="flex items-baseline flex-1 w-full h-8 gap-3 px-4 py-3">
      <InlineInput
        v-model="subject"
        :placeholder="
          t('COMPOSE_NEW_CONVERSATION.FORM.EMAIL_OPTIONS.SUBJECT_PLACEHOLDER')
        "
        :label="t('COMPOSE_NEW_CONVERSATION.FORM.EMAIL_OPTIONS.SUBJECT_LABEL')"
        focus-on-mount
        :custom-input-class="
          hasErrors
            ? 'placeholder:!text-n-ruby-9 dark:placeholder:!text-n-ruby-9'
            : ''
        "
      />
    </div>
    <div class="flex items-baseline flex-1 w-full gap-3 px-4 py-3 min-h-8">
      <label
        class="mb-0.5 text-sm font-medium whitespace-nowrap text-n-slate-11"
      >
        {{ t('COMPOSE_NEW_CONVERSATION.FORM.EMAIL_OPTIONS.CC_LABEL') }}
      </label>
      <div class="flex items-center w-full gap-3 min-h-7">
        <TagInput
          :model-value="ccEmailsArray"
          :placeholder="
            t('COMPOSE_NEW_CONVERSATION.FORM.EMAIL_OPTIONS.CC_PLACEHOLDER')
          "
          :menu-items="contactEmailsList"
          :show-dropdown="showCcEmailsDropdown"
          :is-loading="isLoading"
          type="email"
          class="flex-1 min-h-7"
          @focus="emit('updateDropdown', 'cc', true)"
          @input="emit('searchCcEmails', $event)"
          @on-click-outside="emit('updateDropdown', 'cc', false)"
          @update:model-value="handleCcUpdate"
        />
        <Button
          :label="t('COMPOSE_NEW_CONVERSATION.FORM.EMAIL_OPTIONS.BCC_BUTTON')"
          variant="ghost"
          size="sm"
          color="slate"
          class="flex-shrink-0"
          @click="emit('toggleBcc')"
        />
      </div>
    </div>
    <div
      v-if="showBccInput"
      class="flex items-baseline flex-1 w-full gap-3 px-4 py-3 min-h-8"
    >
      <label
        class="mb-0.5 text-sm font-medium whitespace-nowrap text-n-slate-11"
      >
        {{ t('COMPOSE_NEW_CONVERSATION.FORM.EMAIL_OPTIONS.BCC_LABEL') }}
      </label>
      <TagInput
        :model-value="bccEmailsArray"
        :placeholder="
          t('COMPOSE_NEW_CONVERSATION.FORM.EMAIL_OPTIONS.BCC_PLACEHOLDER')
        "
        :menu-items="contactEmailsList"
        :show-dropdown="showBccEmailsDropdown"
        :is-loading="isLoading"
        type="email"
        class="flex-1 min-h-7"
        focus-on-mount
        @focus="emit('updateDropdown', 'bcc', true)"
        @input="emit('searchBccEmails', $event)"
        @on-click-outside="emit('updateDropdown', 'bcc', false)"
        @update:model-value="handleBccUpdate"
      />
    </div>
  </div>
</template>
