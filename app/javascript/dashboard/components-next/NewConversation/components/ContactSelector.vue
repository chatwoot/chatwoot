<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

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
});
const emit = defineEmits([
  'searchContacts',
  'setSelectedContact',
  'clearSelectedContact',
  'updateDropdown',
]);
const i18nPrefix = 'COMPOSE_NEW_CONVERSATION.FORM.CONTACT_SELECTOR';
const { t } = useI18n();

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
</script>

<template>
  <div class="relative flex-1 px-4 py-3 overflow-y-visible">
    <div class="flex items-baseline w-full gap-3 min-h-7">
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
        class="flex items-center gap-1.5 rounded-md bg-n-alpha-2 px-3 min-h-7 min-w-0"
      >
        <span class="text-sm truncate text-n-slate-12">
          {{
            isCreatingContact
              ? t(`${i18nPrefix}.CONTACT_CREATING`)
              : selectedContactLabel
          }}
        </span>
        <Button
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
        type="email"
        class="flex-1 min-h-7"
        :class="errorClass"
        focus-on-mount
        @input="emit('searchContacts', $event)"
        @on-click-outside="emit('updateDropdown', 'contacts', false)"
        @add="emit('setSelectedContact', $event)"
        @remove="emit('clearSelectedContact')"
      />
    </div>
  </div>
</template>
