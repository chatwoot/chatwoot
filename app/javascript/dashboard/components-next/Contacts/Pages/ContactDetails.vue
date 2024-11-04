<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { debounce } from '@chatwoot/utils';

import EditableAvatar from 'dashboard/components-next/avatar/EditableAvatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ContactLabels from 'dashboard/components-next/Contacts/ContactLabels/ContactLabels.vue';
import ContactsForm from 'dashboard/components-next/Contacts/ContactsForm/ContactsForm.vue';
import ConfirmContactDeleteDialog from 'dashboard/components-next/Contacts/ContactsForm/ConfirmContactDeleteDialog.vue';

const props = defineProps({
  selectedContact: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['goToContactsList']);

const { t } = useI18n();
const store = useStore();

const confirmDeleteContactDialogRef = ref(null);

const selectedContactData = computed(() => {
  if (!props.selectedContact) return {};

  const {
    phone_number: phoneNumber = {},
    additional_attributes: additionalAttributes = {},
  } = props.selectedContact;

  return {
    ...props.selectedContact,
    phoneNumber,
    additionalAttributes,
  };
});

const createdAt = computed(() => {
  return props.selectedContact?.created_at
    ? dynamicTime(props.selectedContact.created_at)
    : '';
});

const lastActivityAt = computed(() => {
  return props.selectedContact?.last_activity_at
    ? dynamicTime(props.selectedContact.last_activity_at)
    : '';
});

const updateContact = async updatedData => {
  await store.dispatch('contacts/update', updatedData);
  await store.dispatch(
    'contacts/fetchContactableInbox',
    props.selectedContact?.id
  );
};

const handleFormUpdate = debounce(
  updatedData => updateContact(updatedData),
  500,
  false
);

const openConfirmDeleteContactDialog = () => {
  confirmDeleteContactDialogRef.value?.dialogRef.open();
};
</script>

<template>
  <div class="flex flex-col items-start gap-8">
    <div class="flex flex-col items-start gap-3">
      <EditableAvatar
        :src="selectedContact.thumbnail"
        :name="selectedContact.name"
      />
      <div class="flex flex-col gap-1">
        <h3 class="text-base font-medium text-n-slate-12">
          {{ selectedContact.name }}
        </h3>
        <span class="text-sm text-n-slate-11">
          {{ createdAt }} • {{ lastActivityAt }}
        </span>
      </div>
      <ContactLabels :contact-id="selectedContact.id" />
    </div>
    <ContactsForm
      :contact-data="selectedContactData"
      is-details-view
      @update="handleFormUpdate"
    />
    <div
      class="flex items-end justify-end w-full gap-4 border-t h-14 border-n-strong"
    >
      <Button
        color="slate"
        :label="t('CONTACTS_LAYOUT.DETAILS.MERGE_CONTACT')"
      />
      <Button
        :label="t('CONTACTS_LAYOUT.DETAILS.DELETE_CONTACT')"
        color="ruby"
        @click="openConfirmDeleteContactDialog"
      />
    </div>
    <ConfirmContactDeleteDialog
      ref="confirmDeleteContactDialogRef"
      :selected-contact="selectedContact"
      @go-to-contacts-list="emit('goToContactsList')"
    />
  </div>
</template>
