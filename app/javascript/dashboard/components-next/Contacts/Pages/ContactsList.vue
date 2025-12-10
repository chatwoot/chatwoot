<script setup>
import { ref, computed } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useRouter, useRoute } from 'vue-router';
import {
  DuplicateContactException,
  ExceptionWithMessage,
} from 'shared/helpers/CustomErrors';
import ContactsCard from 'dashboard/components-next/Contacts/ContactsCard/ContactsCard.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import ConfirmContactDeleteDialog from 'dashboard/components-next/Contacts/ContactsForm/ConfirmContactDeleteDialog.vue';

const props = defineProps({
  contacts: { type: Array, required: true },
  selectedContactIds: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['toggleContact']);

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const route = useRoute();

const uiFlags = useMapGetter('contacts/getUIFlags');
const isUpdating = computed(() => uiFlags.value.isUpdating);
const expandedCardId = ref(null);
const hoveredAvatarId = ref(null);
const selectedContactId = ref(null);
const composeConversationRef = ref(null);
const confirmDeleteContactDialogRef = ref(null);
const contactToDelete = ref(null);

const selectedIdsSet = computed(() => new Set(props.selectedContactIds || []));

const updateContact = async updatedData => {
  try {
    await store.dispatch('contacts/update', updatedData);
    useAlert(t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.SUCCESS_MESSAGE'));
  } catch (error) {
    const i18nPrefix = 'CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.FORM';
    if (error instanceof DuplicateContactException) {
      if (error.data.includes('email')) {
        useAlert(t(`${i18nPrefix}.EMAIL_ADDRESS.DUPLICATE`));
      } else if (error.data.includes('phone_number')) {
        useAlert(t(`${i18nPrefix}.PHONE_NUMBER.DUPLICATE`));
      }
    } else if (error instanceof ExceptionWithMessage) {
      useAlert(error.data);
    } else {
      useAlert(t(`${i18nPrefix}.ERROR_MESSAGE`));
    }
  }
};

const onClickViewDetails = async id => {
  const routeTypes = {
    contacts_dashboard_segments_index: ['contacts_edit_segment', 'segmentId'],
    contacts_dashboard_labels_index: ['contacts_edit_label', 'label'],
  };
  const [name, paramKey] = routeTypes[route.name] || ['contacts_edit'];
  const params = {
    contactId: id,
    ...(paramKey && { [paramKey]: route.params[paramKey] }),
  };

  await router.push({ name, params, query: route.query });
};

const toggleExpanded = async id => {
  const isExpanding = expandedCardId.value !== id;
  expandedCardId.value = expandedCardId.value === id ? null : id;

  // Fetch contactable inboxes when expanding a card
  if (isExpanding) {
    try {
      await store.dispatch('contacts/fetchContactableInbox', id);
    } catch (error) {
      // error
    }
  }
};

const isSelected = id => selectedIdsSet.value.has(id);

const shouldShowSelection = id => {
  return hoveredAvatarId.value === id || isSelected(id);
};

const handleSelect = (id, value) => {
  emit('toggleContact', { id, value });
};

const handleAvatarHover = (id, isHovered) => {
  hoveredAvatarId.value = isHovered ? id : null;
};

const handleSendMessage = id => {
  selectedContactId.value = String(id);
  composeConversationRef.value?.toggle();
};

const handleDeleteContact = id => {
  const contact = props.contacts.find(c => c.id === id);
  if (contact) {
    contactToDelete.value = { id: contact.id, name: contact.name };
    confirmDeleteContactDialogRef.value?.dialogRef.open();
  }
};
</script>

<template>
  <div class="flex flex-col divide-y divide-n-slate-3">
    <div v-for="contact in contacts" :key="contact.id" class="relative">
      <ContactsCard
        :id="contact.id"
        :name="contact.name"
        :email="contact.email"
        :thumbnail="contact.thumbnail"
        :phone-number="contact.phoneNumber"
        :additional-attributes="contact.additionalAttributes"
        :availability-status="contact.availabilityStatus"
        :is-expanded="expandedCardId === contact.id"
        :is-updating="isUpdating"
        :selectable="shouldShowSelection(contact.id)"
        :is-selected="isSelected(contact.id)"
        :labels="contact.labels || []"
        @toggle="toggleExpanded(contact.id)"
        @update-contact="updateContact"
        @show-contact="onClickViewDetails"
        @select="value => handleSelect(contact.id, value)"
        @avatar-hover="value => handleAvatarHover(contact.id, value)"
        @send-message="handleSendMessage"
        @delete-contact="handleDeleteContact"
      />
    </div>
    <ComposeConversation
      ref="composeConversationRef"
      :contact-id="selectedContactId"
      is-modal
    >
      <template #trigger="{ toggle }">
        <button
          type="button"
          class="hidden"
          aria-hidden="true"
          @click="toggle"
        />
      </template>
    </ComposeConversation>
    <ConfirmContactDeleteDialog
      ref="confirmDeleteContactDialogRef"
      :selected-contact="contactToDelete"
    />
  </div>
</template>
