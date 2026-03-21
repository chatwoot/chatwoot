<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { debounce } from '@chatwoot/utils';
import ContactsAPI from 'dashboard/api/contacts';

import wootConstants from 'dashboard/constants/globals';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';

const props = defineProps({
  inboxes: { type: Array, default: () => [] },
  isCreating: { type: Boolean, default: false },
  isGroupsDisabled: { type: Boolean, default: false },
  isSuperAdmin: { type: Boolean, default: false },
});

const emit = defineEmits(['createGroup', 'discard']);

const { t } = useI18n();

const groupName = ref('');
const selectedInbox = ref(null);
const showInboxDropdown = ref(false);
const participants = ref([]);
const contactResults = ref([]);
const showContactsDropdown = ref(false);
const isSearching = ref(false);
const nameTouched = ref(false);
const participantsTouched = ref(false);
const participantsFocused = ref(false);

const inboxMenuItems = computed(() =>
  props.inboxes.map(inbox => ({
    label: inbox.name,
    value: inbox.id,
    action: 'select',
  }))
);

const contactMenuItems = computed(() =>
  contactResults.value.map(contact => ({
    id: contact.id,
    label: contact.phone_number
      ? `${contact.name} (${contact.phone_number})`
      : contact.name,
    value: contact.id,
    action: 'contact',
    thumbnail: { name: contact.name, src: contact.thumbnail },
    phoneNumber: contact.phone_number,
    name: contact.name,
  }))
);

const participantTags = computed(() =>
  participants.value.map(p => p.name || p.phone_number)
);

const showNameError = computed(
  () => nameTouched.value && !groupName.value.trim()
);
const showParticipantsError = computed(
  () => participantsTouched.value && participants.value.length === 0
);

const isFormValid = computed(
  () =>
    selectedInbox.value &&
    groupName.value.trim() &&
    participants.value.length > 0
);

const searchContacts = debounce(
  async query => {
    if (!query || query.length < 2) {
      contactResults.value = [];
      showContactsDropdown.value = false;
      return;
    }
    isSearching.value = true;
    try {
      const { data } = await ContactsAPI.search(query);
      const selectedIds = participants.value.map(p => p.id);
      contactResults.value = (data.payload || []).filter(
        contact => contact.phone_number && !selectedIds.includes(contact.id)
      );
      showContactsDropdown.value = contactResults.value.length > 0;
    } catch {
      contactResults.value = [];
    } finally {
      isSearching.value = false;
    }
  },
  300,
  false
);

const handleInboxAction = item => {
  const inbox = props.inboxes.find(i => i.id === item.value);
  selectedInbox.value = inbox;
  showInboxDropdown.value = false;
};

const clearInbox = () => {
  selectedInbox.value = null;
};

const handleAddParticipant = item => {
  const contact = contactResults.value.find(c => c.id === item.value);
  if (contact) {
    participants.value = [...participants.value, contact];
    participantsTouched.value = true;
    contactResults.value = [];
    showContactsDropdown.value = false;
  }
};

const handleRemoveParticipant = index => {
  participants.value = participants.value.filter((_, i) => i !== index);
  participantsTouched.value = true;
};

const handleNameBlur = () => {
  nameTouched.value = true;
};

const handleParticipantsFocus = () => {
  participantsFocused.value = true;
};

const handleParticipantsBlur = () => {
  showContactsDropdown.value = false;
  if (participantsFocused.value && participants.value.length === 0) {
    participantsTouched.value = true;
  }
};

const resetForm = () => {
  groupName.value = '';
  selectedInbox.value = null;
  participants.value = [];
  contactResults.value = [];
  showContactsDropdown.value = false;
  showInboxDropdown.value = false;
  nameTouched.value = false;
  participantsTouched.value = false;
  participantsFocused.value = false;
};

const handleSubmit = () => {
  if (!isFormValid.value) return;
  emit('createGroup', {
    inboxId: selectedInbox.value.id,
    subject: groupName.value.trim(),
    participants: participants.value.map(p => p.phone_number),
  });
};

defineExpose({ resetForm });
</script>

<template>
  <div
    class="w-[42rem] divide-y divide-n-strong overflow-visible transition-all duration-300 ease-in-out top-full flex flex-col bg-n-alpha-3 border border-n-strong shadow-sm backdrop-blur-[100px] rounded-xl min-w-0 max-h-[calc(100vh-8rem)]"
  >
    <div class="flex-1 divide-y divide-n-strong overflow-visible">
      <div
        v-if="isGroupsDisabled"
        class="flex items-center gap-2 mx-4 mt-3 px-3 py-2 rounded-lg text-sm text-n-amber-11 bg-n-amber-2"
      >
        <span class="i-lucide-triangle-alert text-base flex-shrink-0" />
        <span v-if="isSuperAdmin">
          {{ t('GROUP.CREATE.GROUPS_DISABLED') }}
          <a
            :href="wootConstants.FAZER_AI_GUIDES_URL"
            target="_blank"
            rel="noopener noreferrer"
            class="underline font-medium"
          >
            {{ t('GROUP.CREATE.GROUPS_DISABLED_CTA') }}
          </a>
        </span>
        <span v-else>
          {{ t('GROUP.CREATE.GROUPS_DISABLED_NON_ADMIN') }}
        </span>
      </div>
      <div
        class="flex items-center flex-1 w-full gap-3 px-4 py-3 overflow-y-visible"
      >
        <label
          class="mb-0.5 text-sm font-medium text-n-slate-11 whitespace-nowrap"
        >
          {{ t('GROUP.CREATE.INBOX_LABEL') }}
        </label>
        <div class="relative flex-1 min-w-0">
          <div
            v-if="selectedInbox"
            class="flex items-center gap-1.5 rounded-md bg-n-alpha-2 truncate ltr:pl-3 rtl:pr-3 ltr:pr-1 rtl:pl-1 h-7 min-w-0"
          >
            <span class="text-sm truncate text-n-slate-12">
              {{ selectedInbox.name }}
            </span>
            <Button
              variant="ghost"
              icon="i-lucide-x"
              color="slate"
              size="xs"
              class="flex-shrink-0"
              @click="clearInbox"
            />
          </div>
          <div v-else class="relative">
            <Button
              :label="t('GROUP.CREATE.INBOX_PLACEHOLDER')"
              variant="link"
              size="sm"
              color="slate"
              class="hover:!no-underline"
              @click="showInboxDropdown = !showInboxDropdown"
            />
            <DropdownMenu
              v-if="showInboxDropdown"
              :menu-items="inboxMenuItems"
              class="z-[100] top-9 w-full max-h-48 overflow-y-auto dark:!outline-n-slate-5"
              @action="handleInboxAction"
            />
          </div>
        </div>
      </div>

      <div
        class="flex items-start flex-1 w-full gap-3 px-4 py-3 overflow-y-visible"
      >
        <label
          class="mb-0.5 text-sm font-medium whitespace-nowrap mt-1"
          :class="showNameError ? 'text-n-ruby-9' : 'text-n-slate-11'"
        >
          {{ t('GROUP.CREATE.NAME_LABEL') }}
        </label>
        <div class="flex flex-col flex-1 min-w-0">
          <input
            v-model="groupName"
            type="text"
            class="w-full px-2 py-1 text-sm rounded-md bg-transparent text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none border"
            :class="showNameError ? 'border-n-ruby-9' : 'border-transparent'"
            :placeholder="t('GROUP.CREATE.NAME_PLACEHOLDER')"
            @blur="handleNameBlur"
          />
          <span v-if="showNameError" class="text-xs text-n-ruby-9 mt-0.5 px-2">
            {{ t('GROUP.CREATE.NAME_REQUIRED') }}
          </span>
        </div>
      </div>

      <div class="relative flex flex-col gap-1 px-4 py-3">
        <label
          class="mb-0.5 text-sm font-medium whitespace-nowrap"
          :class="showParticipantsError ? 'text-n-ruby-9' : 'text-n-slate-11'"
        >
          {{ t('GROUP.CREATE.PARTICIPANTS_LABEL') }}
        </label>
        <TagInput
          :model-value="participantTags"
          :placeholder="t('GROUP.CREATE.PARTICIPANTS_PLACEHOLDER')"
          mode="multiple"
          :menu-items="contactMenuItems"
          :show-dropdown="showContactsDropdown"
          :is-loading="isSearching"
          skip-label-dedup
          :auto-open-dropdown="false"
          :class="showParticipantsError ? '!border-n-ruby-9' : ''"
          @input="searchContacts"
          @focus="handleParticipantsFocus"
          @on-click-outside="handleParticipantsBlur"
          @add="handleAddParticipant"
          @remove="handleRemoveParticipant"
        />
        <span v-if="showParticipantsError" class="text-xs text-n-ruby-9">
          {{ t('GROUP.CREATE.PARTICIPANTS_REQUIRED') }}
        </span>
      </div>
    </div>

    <div class="flex items-center justify-between gap-2 px-4 py-3">
      <div />
      <div class="flex items-center gap-2">
        <Button
          :label="t('COMPOSE_NEW_CONVERSATION.FORM.ACTION_BUTTONS.DISCARD')"
          variant="faded"
          color="slate"
          size="sm"
          @click="
            resetForm();
            emit('discard');
          "
        />
        <Button
          :label="t('GROUP.CREATE.SUBMIT_BUTTON')"
          color="blue"
          size="sm"
          :disabled="!isFormValid || isCreating || isGroupsDisabled"
          :is-loading="isCreating"
          @click="handleSubmit"
        />
      </div>
    </div>
  </div>
</template>
