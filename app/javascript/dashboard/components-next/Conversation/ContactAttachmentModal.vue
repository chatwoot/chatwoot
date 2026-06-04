<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Modal from 'dashboard/components/Modal.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import { useAlert } from 'dashboard/composables';
import { createContactSearcher } from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper.js';

const props = defineProps({
  selectedContacts: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['attach', 'close', 'update:show']);
const show = defineModel('show', { type: Boolean, default: false });

const { t } = useI18n();
const searchContacts = createContactSearcher();

const query = ref('');
const contacts = ref([]);
const selectedMap = ref({});
const isSearching = ref(false);

const selectedContactsList = computed(() => Object.values(selectedMap.value));

const contactDisplayName = contact => {
  return (
    contact.formattedName ||
    contact.name ||
    [contact.firstName, contact.lastName].filter(Boolean).join(' ') ||
    ''
  );
};

const contactDisplayPhone = contact => {
  return contact.phoneNumber || contact.phone_number || contact.email || '';
};

const selectedCountLabel = computed(() =>
  t('CONVERSATION.REPLYBOX.CONTACT_ATTACHER.SELECTED_COUNT', {
    count: selectedContactsList.value.length,
  })
);

const syncSelection = contactsList => {
  selectedMap.value = contactsList.reduce((acc, contact) => {
    acc[contact.id] = contact;
    return acc;
  }, {});
};

const resetState = () => {
  query.value = '';
  contacts.value = [];
  syncSelection(props.selectedContacts);
};

const close = () => {
  show.value = false;
  emit('close');
};

const toggleContact = contact => {
  if (selectedMap.value[contact.id]) {
    const nextValue = { ...selectedMap.value };
    delete nextValue[contact.id];
    selectedMap.value = nextValue;
    return;
  }

  selectedMap.value = {
    ...selectedMap.value,
    [contact.id]: contact,
  };
};

const handleAttach = () => {
  if (!selectedContactsList.value.length) {
    useAlert(t('CONVERSATION.REPLYBOX.CONTACT_ATTACHER.EMPTY'));
    return;
  }

  emit('attach', selectedContactsList.value);
};

const handleSearch = async value => {
  query.value = value;
  const trimmedValue = value.trim();

  if (!trimmedValue) {
    contacts.value = [];
    return;
  }

  isSearching.value = true;
  try {
    const result = await searchContacts(trimmedValue, { skipMinLength: true });
    if (result) {
      contacts.value = result;
    }
  } catch (error) {
    useAlert(t('CONTACTS_LAYOUT.MERGE_CONTACTS.SEARCH_ERROR_MESSAGE'));
  } finally {
    isSearching.value = false;
  }
};

watch(
  () => show.value,
  isVisible => {
    if (isVisible) {
      resetState();
    }
  }
);
</script>

<template>
  <Modal v-model:show="show" :on-close="close">
    <woot-modal-header
      :header-title="$t('CONVERSATION.REPLYBOX.CONTACT_ATTACHER.TITLE')"
      :header-content="$t('CONVERSATION.REPLYBOX.CONTACT_ATTACHER.SUBTITLE')"
    />

    <div class="flex flex-col gap-4 p-8">
      <div class="rounded-lg border border-n-weak bg-n-alpha-2 px-3 py-2">
        <InlineInput
          :model-value="query"
          focus-on-mount
          :placeholder="
            $t('CONVERSATION.REPLYBOX.CONTACT_ATTACHER.SEARCH_PLACEHOLDER')
          "
          @input="handleSearch"
        />
      </div>

      <p class="text-xs text-n-slate-11">
        {{ selectedCountLabel }}
      </p>

      <div class="max-h-80 overflow-y-auto rounded-lg border border-n-weak">
        <div
          v-if="isSearching"
          class="px-4 py-6 text-sm text-center text-n-slate-11"
        >
          {{ $t('CONVERSATION.SEARCH.LOADING_MESSAGE') }}
        </div>
        <div
          v-else-if="!contacts.length"
          class="px-4 py-6 text-sm text-center text-n-slate-11"
        >
          {{ $t('CONVERSATION.REPLYBOX.CONTACT_ATTACHER.EMPTY') }}
        </div>
        <button
          v-for="contact in contacts"
          :key="contact.id"
          type="button"
          class="flex items-center gap-3 w-full px-4 py-3 text-left border-b border-n-weak last:border-b-0 hover:bg-n-alpha-2"
          @click="toggleContact(contact)"
        >
          <Checkbox :model-value="!!selectedMap[contact.id]" />
          <Avatar
            :name="contactDisplayName(contact)"
            :src="contact.thumbnail"
            :size="32"
          />
          <div class="min-w-0">
            <p class="text-sm font-medium truncate text-n-slate-12">
              {{ contactDisplayName(contact) }}
            </p>
            <p class="text-xs truncate text-n-slate-11">
              {{ contactDisplayPhone(contact) }}
            </p>
          </div>
        </button>
      </div>

      <div class="flex justify-end gap-2">
        <Button
          variant="ghost"
          color="slate"
          size="sm"
          :label="$t('CONVERSATION.REPLYBOX.CONTACT_ATTACHER.CANCEL')"
          @click="close"
        />
        <Button
          color="blue"
          size="sm"
          :disabled="!selectedContactsList.length"
          :label="$t('CONVERSATION.REPLYBOX.CONTACT_ATTACHER.ATTACH')"
          @click="handleAttach"
        />
      </div>
    </div>
  </Modal>
</template>
