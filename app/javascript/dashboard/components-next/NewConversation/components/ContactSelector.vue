<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { INPUT_TYPES } from 'dashboard/components-next/taginput/helper/tagInputHelper.js';

import TagInput from 'dashboard/components-next/taginput/TagInput.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  contacts: {
    type: Array,
    required: true,
  },
  selectedContact: {
    type: Object,
    default: null,
  },
  showContactsDropdown: {
    type: Boolean,
    required: true,
  },
  isLoading: {
    type: Boolean,
    required: true,
  },
  isCreatingContact: {
    type: Boolean,
    required: true,
  },
  contactId: {
    type: String,
    default: null,
  },
  contactableInboxesList: {
    type: Array,
    default: () => [],
  },
  showInboxesDropdown: {
    type: Boolean,
    required: true,
  },
  hasErrors: {
    type: Boolean,
    default: false,
  },
  // Additional To recipients are only supported on email inboxes, where the
  // channel can deliver a single message to more than one address.
  allowAdditionalRecipients: {
    type: Boolean,
    default: false,
  },
  showToEmailsDropdown: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'searchContacts',
  'searchToEmails',
  'setSelectedContact',
  'clearSelectedContact',
  'updateDropdown',
]);

const i18nPrefix = 'COMPOSE_NEW_CONVERSATION.FORM.CONTACT_SELECTOR';
const { t } = useI18n();

const inputType = ref(INPUT_TYPES.EMAIL);

const toEmails = defineModel('toEmails', { type: String, default: '' });

const toEmailsArray = computed(() =>
  toEmails.value ? toEmails.value.split(',').map(email => email.trim()) : []
);

const handleToEmailsUpdate = value => {
  toEmails.value = value.join(',');
};

const contactsList = computed(() => {
  return props.contacts?.map(({ name, id, thumbnail, email, ...rest }) => ({
    id,
    label: email ? `${name} (${email})` : name,
    value: id,
    thumbnail: { name, src: thumbnail },
    ...rest,
    name,
    email,
    action: 'contact',
  }));
});

const contactEmailsList = computed(() =>
  props.contacts
    ?.filter(({ email }) => email && email !== props.selectedContact?.email)
    .map(({ name, id, email }) => ({
      id,
      label: email,
      email,
      thumbnail: { name, src: '' },
      value: id,
      action: 'email',
    }))
);

const selectedContactLabel = computed(() => {
  const { name, email = '', phoneNumber = '' } = props.selectedContact || {};
  if (email) {
    return `${name} (${email})`;
  }
  if (phoneNumber) {
    return `${name} (${phoneNumber})`;
  }
  return name || '';
});

const errorClass = computed(() => {
  return props.hasErrors
    ? '[&_input]:placeholder:!text-n-ruby-9 [&_input]:dark:placeholder:!text-n-ruby-9'
    : '';
});

const handleInput = value => {
  // Update input type based on whether input starts with '+'
  // If it does, set input type to 'tel'
  // Otherwise, set input type to 'email'
  inputType.value = value.startsWith('+') ? INPUT_TYPES.TEL : INPUT_TYPES.EMAIL;
  emit('searchContacts', value);
};
</script>

<template>
  <div class="relative flex-1 px-4 py-3 overflow-y-visible">
    <div class="flex flex-wrap items-baseline w-full gap-3 min-h-7">
      <label class="text-sm font-medium text-n-slate-11 whitespace-nowrap">
        {{ t(`${i18nPrefix}.LABEL`) }}
      </label>

      <div
        v-if="isCreatingContact"
        class="flex items-center gap-1.5 rounded-md bg-n-alpha-2 px-3 min-h-7 min-w-0"
      >
        <span class="text-sm truncate text-n-slate-12">
          {{ t(`${i18nPrefix}.CONTACT_CREATING`) }}
        </span>
      </div>
      <div
        v-else-if="selectedContact"
        class="flex items-center gap-1.5 rounded-md bg-n-alpha-2 min-h-7 min-w-0"
        :class="!contactId ? 'ltr:pl-3 rtl:pr-3 ltr:pr-1 rtl:pl-1' : 'px-3'"
      >
        <span class="text-sm truncate text-n-slate-12">
          {{
            isCreatingContact
              ? t(`${i18nPrefix}.CONTACT_CREATING`)
              : selectedContactLabel
          }}
        </span>
        <Button
          v-if="!contactId"
          variant="ghost"
          icon="i-lucide-x"
          color="slate"
          :disabled="contactId"
          size="xs"
          @click="emit('clearSelectedContact')"
        />
      </div>
      <TagInput
        v-else
        :placeholder="t(`${i18nPrefix}.TAG_INPUT_PLACEHOLDER`)"
        mode="single"
        :menu-items="contactsList"
        :show-dropdown="showContactsDropdown"
        :is-loading="isLoading"
        :disabled="contactableInboxesList?.length > 0 && showInboxesDropdown"
        allow-create
        :type="inputType"
        class="flex-1 min-h-7"
        :class="errorClass"
        focus-on-mount
        @input="handleInput"
        @on-click-outside="emit('updateDropdown', 'contacts', false)"
        @add="emit('setSelectedContact', $event)"
        @remove="emit('clearSelectedContact')"
      />
      <TagInput
        v-if="selectedContact && allowAdditionalRecipients"
        :model-value="toEmailsArray"
        :placeholder="t(`${i18nPrefix}.ADDITIONAL_RECIPIENTS_PLACEHOLDER`)"
        :menu-items="contactEmailsList"
        :show-dropdown="showToEmailsDropdown"
        :is-loading="isLoading"
        type="email"
        allow-create
        class="flex-1 min-h-7"
        @input="emit('searchToEmails', $event)"
        @on-click-outside="emit('updateDropdown', 'to', false)"
        @update:model-value="handleToEmailsUpdate"
      />
    </div>
  </div>
</template>
