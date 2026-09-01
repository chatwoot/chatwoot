<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { debounce } from '@chatwoot/utils';
import { createContactSearcher } from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper';

import TagInput from 'dashboard/components-next/taginput/TagInput.vue';
import ButtonV4 from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();

const toEmails = defineModel('toEmails', { type: String, default: '' });
const ccEmails = defineModel('ccEmails', { type: String, default: '' });
const bccEmails = defineModel('bccEmails', { type: String, default: '' });

const MIN_SEARCH_LENGTH = 2;

const searchContacts = createContactSearcher();

const contacts = ref([]);
const isSearching = ref(false);
// Only one recipient field can own the suggestion dropdown at a time.
const activeField = ref('');
const isBccRequested = ref(false);

const showBcc = computed(() => isBccRequested.value || !!bccEmails.value);

const splitEmails = value =>
  value
    ? value
        .split(',')
        .map(email => email.trim())
        .filter(Boolean)
    : [];

const toEmailsArray = computed(() => splitEmails(toEmails.value));
const ccEmailsArray = computed(() => splitEmails(ccEmails.value));
const bccEmailsArray = computed(() => splitEmails(bccEmails.value));

const contactEmailsList = computed(() =>
  contacts.value
    .filter(({ email }) => email)
    .map(({ name, id, email }) => ({
      id,
      label: email,
      email,
      thumbnail: { name, src: '' },
      value: id,
      action: 'email',
    }))
);

const runSearch = debounce(
  async query => {
    isSearching.value = true;
    try {
      const results = await searchContacts(query);
      // null means the request was aborted because a newer search started.
      if (results === null) return;
      contacts.value = results;
    } catch (error) {
      contacts.value = [];
    }
    isSearching.value = false;
  },
  400,
  false
);

const handleSearch = (field, value) => {
  const query = value.trim();
  contacts.value = [];
  activeField.value = query.length >= MIN_SEARCH_LENGTH ? field : '';
  runSearch(query);
};

const closeDropdown = field => {
  if (activeField.value === field) activeField.value = '';
};

const updateToEmails = value => {
  toEmails.value = value.join(',');
};

const updateCcEmails = value => {
  ccEmails.value = value.join(',');
};

const updateBccEmails = value => {
  bccEmails.value = value.join(',');
};
</script>

<template>
  <div class="flex flex-col">
    <div
      class="flex items-center gap-2 my-1 border-b border-solid border-n-weak"
    >
      <label
        class="pl-0 text-xs font-semibold bg-transparent border-transparent"
      >
        {{ t('CONVERSATION.REPLYBOX.EMAIL_HEAD.TO') }}
      </label>
      <TagInput
        :model-value="toEmailsArray"
        :placeholder="t('CONVERSATION.REPLYBOX.EMAIL_HEAD.SEARCH_PLACEHOLDER')"
        :menu-items="contactEmailsList"
        :show-dropdown="activeField === 'to'"
        :is-loading="isSearching"
        type="email"
        allow-create
        :auto-open-dropdown="false"
        class="flex-1 min-h-7"
        @input="handleSearch('to', $event)"
        @on-click-outside="closeDropdown('to')"
        @update:model-value="updateToEmails"
      />
    </div>
    <div
      class="flex items-center gap-2 my-1 border-b border-solid border-n-weak"
    >
      <label
        class="pl-0 text-xs font-semibold bg-transparent border-transparent"
      >
        {{ t('CONVERSATION.REPLYBOX.EMAIL_HEAD.CC.LABEL') }}
      </label>
      <TagInput
        :model-value="ccEmailsArray"
        :placeholder="t('CONVERSATION.REPLYBOX.EMAIL_HEAD.SEARCH_PLACEHOLDER')"
        :menu-items="contactEmailsList"
        :show-dropdown="activeField === 'cc'"
        :is-loading="isSearching"
        type="email"
        allow-create
        :auto-open-dropdown="false"
        class="flex-1 min-h-7"
        @input="handleSearch('cc', $event)"
        @on-click-outside="closeDropdown('cc')"
        @update:model-value="updateCcEmails"
      />
      <ButtonV4
        v-if="!showBcc"
        :label="t('CONVERSATION.REPLYBOX.EMAIL_HEAD.ADD_BCC')"
        ghost
        xs
        primary
        @click="isBccRequested = true"
      />
    </div>
    <div
      v-if="showBcc"
      class="flex items-center gap-2 my-1 border-b border-solid border-n-weak"
    >
      <label
        class="pl-0 text-xs font-semibold bg-transparent border-transparent"
      >
        {{ t('CONVERSATION.REPLYBOX.EMAIL_HEAD.BCC.LABEL') }}
      </label>
      <TagInput
        :model-value="bccEmailsArray"
        :placeholder="t('CONVERSATION.REPLYBOX.EMAIL_HEAD.SEARCH_PLACEHOLDER')"
        :menu-items="contactEmailsList"
        :show-dropdown="activeField === 'bcc'"
        :is-loading="isSearching"
        type="email"
        allow-create
        :auto-open-dropdown="false"
        class="flex-1 min-h-7"
        @input="handleSearch('bcc', $event)"
        @on-click-outside="closeDropdown('bcc')"
        @update:model-value="updateBccEmails"
      />
    </div>
  </div>
</template>
