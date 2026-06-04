<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { createContactSearcher } from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper.js';
import conversationApi from 'dashboard/api/inbox/conversation';
import Avatar from 'next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';
import Modal from 'dashboard/components/Modal.vue';

const props = defineProps({
  inboxes: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['groupCreated']);
const show = defineModel('show', { type: Boolean, default: false });

const { t } = useI18n();
const searchContacts = createContactSearcher();

const subject = ref('');
const description = ref('');
const selectedInboxId = ref('');
const joinApprovalMode = ref('');
const query = ref('');
const contacts = ref([]);
const selectedMap = ref({});
const isSearching = ref(false);
const isSaving = ref(false);

const normalizedValue = value => (value || '').toString().toLowerCase();

const isUnoapiWhatsappInbox = inbox => {
  const channelType = normalizedValue(inbox.channel_type || inbox.channelType);
  const provider = normalizedValue(
    inbox.provider || inbox.providerName || inbox.provider_name
  );

  return channelType.includes('whatsapp') && provider.includes('uno');
};

const unoapiInboxes = computed(() =>
  props.inboxes.filter(inbox => isUnoapiWhatsappInbox(inbox))
);

const selectedContacts = computed(() => Object.values(selectedMap.value));

const contactName = contact =>
  contact.formattedName ||
  contact.name ||
  [contact.firstName, contact.lastName].filter(Boolean).join(' ') ||
  contact.phoneNumber ||
  contact.bsuid;

const contactSubtitle = contact =>
  [contact.whatsappUsername, contact.phoneNumber, contact.bsuid]
    .filter(Boolean)
    .join(' · ');

const digitsOnly = value => value?.toString().replace(/\D/g, '') || '';

const phoneIdentifier = value => {
  const sourceId = value || '';
  if (sourceId.endsWith('@lid')) return '';
  return digitsOnly(sourceId);
};

const sourceParticipantId = contact => {
  const sourceId =
    contact.sourceId ||
    contact.source_id ||
    contact.contactInboxes?.find(inbox => inbox.sourceId || inbox.source_id)
      ?.sourceId ||
    contact.contactInboxes?.find(inbox => inbox.sourceId || inbox.source_id)
      ?.source_id;

  if (!sourceId) return '';
  if (sourceId.endsWith('@lid') || sourceId.endsWith('@s.whatsapp.net')) {
    return sourceId;
  }

  const digits = digitsOnly(sourceId);
  return digits.length >= 8 ? digits : '';
};

const participantPayload = contact => {
  const sourceId = sourceParticipantId(contact);
  const waId = digitsOnly(contact.phoneNumber) || phoneIdentifier(sourceId);
  const userId = contact.bsuid || (sourceId.endsWith('@lid') ? sourceId : '');

  return {
    ...(waId ? { wa_id: waId } : {}),
    ...(userId ? { user_id: userId } : {}),
  };
};

const canAddContact = contact => {
  const payload = participantPayload(contact);
  return !!(payload.wa_id || payload.user_id);
};

const selectedCountLabel = computed(() =>
  t('CONVERSATION.GROUP.CREATE_SELECTED', {
    count: selectedContacts.value.length,
  })
);

const resetState = () => {
  subject.value = '';
  description.value = '';
  selectedInboxId.value = unoapiInboxes.value[0]?.id || '';
  joinApprovalMode.value = '';
  query.value = '';
  contacts.value = [];
  selectedMap.value = {};
};

const close = () => {
  show.value = false;
};

const toggleContact = contact => {
  if (!canAddContact(contact)) return;

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

const handleSearch = async value => {
  query.value = value;
  const trimmedValue = value.trim();

  if (trimmedValue.length < 2) {
    contacts.value = [];
    return;
  }

  isSearching.value = true;
  try {
    const result = await searchContacts(trimmedValue);
    if (result) {
      contacts.value = result.filter(canAddContact);
    }
  } catch (error) {
    useAlert(t('CONTACTS_LAYOUT.MERGE_CONTACTS.SEARCH_ERROR_MESSAGE'));
  } finally {
    isSearching.value = false;
  }
};

const createGroup = async () => {
  if (!selectedInboxId.value || !subject.value.trim()) {
    useAlert(t('CONVERSATION.GROUP.CREATE_REQUIRED'));
    return;
  }

  const participants = selectedContacts.value.map(participantPayload);
  if (!participants.length) {
    useAlert(t('CONVERSATION.GROUP.CREATE_PARTICIPANTS_REQUIRED'));
    return;
  }

  isSaving.value = true;
  try {
    const { data } = await conversationApi.createGroup({
      inboxId: selectedInboxId.value,
      subject: subject.value.trim(),
      description: description.value.trim(),
      participants,
      joinApprovalMode: joinApprovalMode.value || undefined,
    });

    close();
    emit('groupCreated', data);
  } catch (error) {
    useAlert(
      error.response?.data?.error ||
        error.message ||
        t('CONVERSATION.GROUP.CREATE_ERROR')
    );
  } finally {
    isSaving.value = false;
  }
};

watch(
  () => show.value,
  isVisible => {
    if (isVisible) resetState();
  }
);
</script>

<template>
  <Modal v-model:show="show" size="medium" :on-close="close">
    <div class="flex max-h-[42rem] flex-col">
      <div class="border-b border-n-weak px-6 py-5">
        <h3 class="m-0 text-lg font-medium text-n-slate-12">
          {{ $t('CONVERSATION.GROUP.CREATE_GROUP') }}
        </h3>
        <p class="m-0 text-sm text-n-slate-10">
          {{ $t('CONVERSATION.GROUP.CREATE_GROUP_SUBTITLE') }}
        </p>
      </div>

      <div class="flex flex-1 flex-col gap-3 overflow-hidden px-6 py-4">
        <select
          v-model="selectedInboxId"
          class="w-full rounded-md border border-n-weak bg-n-background px-3 py-2 text-sm text-n-slate-12"
        >
          <option value="" disabled>
            {{ $t('CONVERSATION.GROUP.SELECT_INBOX') }}
          </option>
          <option
            v-for="inbox in unoapiInboxes"
            :key="inbox.id"
            :value="inbox.id"
          >
            {{ inbox.name }}
          </option>
        </select>

        <input
          v-model.trim="subject"
          type="text"
          class="w-full rounded-md border border-n-weak bg-n-background px-3 py-2 text-sm text-n-slate-12"
          :placeholder="$t('CONVERSATION.GROUP.TITLE')"
        />

        <textarea
          v-model.trim="description"
          rows="2"
          class="w-full rounded-md border border-n-weak bg-n-background px-3 py-2 text-sm text-n-slate-12"
          :placeholder="$t('CONVERSATION.GROUP.DESCRIPTION')"
        />

        <select
          v-model="joinApprovalMode"
          class="w-full rounded-md border border-n-weak bg-n-background px-3 py-2 text-sm text-n-slate-12"
        >
          <option value="">
            {{ $t('CONVERSATION.GROUP.JOIN_APPROVAL_DEFAULT') }}
          </option>
          <option value="on">
            {{ $t('CONVERSATION.GROUP.JOIN_APPROVAL_ON') }}
          </option>
          <option value="off">
            {{ $t('CONVERSATION.GROUP.JOIN_APPROVAL_OFF') }}
          </option>
        </select>

        <div class="rounded-md border border-n-weak bg-n-background px-3 py-2">
          <InlineInput
            :model-value="query"
            :placeholder="$t('CONVERSATION.GROUP.SEARCH_CONTACTS')"
            @input="handleSearch"
          />
        </div>

        <p class="m-0 text-xs text-n-slate-11">
          {{ selectedCountLabel }}
        </p>

        <div class="flex-1 overflow-y-auto rounded-md border border-n-weak">
          <div
            v-if="isSearching"
            class="px-4 py-6 text-center text-sm text-n-slate-11"
          >
            {{ $t('CONVERSATION.SEARCH.LOADING_MESSAGE') }}
          </div>
          <div
            v-else-if="!contacts.length"
            class="px-4 py-6 text-center text-sm text-n-slate-11"
          >
            {{ $t('CONVERSATION.GROUP.NO_CONTACTS_FOUND') }}
          </div>
          <button
            v-for="contact in contacts"
            :key="contact.id"
            type="button"
            class="flex w-full items-center gap-3 border-b border-n-weak px-4 py-3 text-left last:border-b-0 hover:bg-n-alpha-2"
            @click="toggleContact(contact)"
          >
            <Checkbox :model-value="!!selectedMap[contact.id]" />
            <Avatar
              :name="contactName(contact)"
              :src="contact.thumbnail"
              :size="36"
              hide-offline-status
            />
            <span class="min-w-0 flex-1">
              <span class="block truncate text-sm font-medium text-n-slate-12">
                {{ contactName(contact) }}
              </span>
              <span
                v-if="contactSubtitle(contact)"
                class="block truncate text-xs text-n-slate-10"
              >
                {{ contactSubtitle(contact) }}
              </span>
            </span>
          </button>
        </div>

        <div class="flex justify-end gap-2">
          <Button
            variant="ghost"
            color="slate"
            size="sm"
            :label="$t('CONVERSATION.GROUP.CANCEL')"
            :disabled="isSaving"
            @click="close"
          />
          <Button
            color="blue"
            size="sm"
            :label="$t('CONVERSATION.GROUP.CREATE_GROUP')"
            :disabled="!selectedInboxId || !subject || !selectedContacts.length"
            :is-loading="isSaving"
            @click="createGroup"
          />
        </div>
      </div>
    </div>
  </Modal>
</template>
