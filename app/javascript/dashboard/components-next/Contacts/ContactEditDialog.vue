<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ContactsForm from 'dashboard/components-next/Contacts/ContactsForm/ContactsForm.vue';

const props = defineProps({
  selectedContact: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);
const contactsFormRef = ref(null);
const contactData = ref({});

const uiFlags = useMapGetter('contacts/getUIFlags');
const isUpdating = computed(() => uiFlags.value.isUpdating);
const isFormInvalid = computed(() => contactsFormRef.value?.isFormInvalid);

watch(
  () => props.selectedContact,
  newContact => {
    contactData.value = newContact ? { ...newContact } : {};
  },
  { immediate: true }
);

const handleFormUpdate = updatedData => {
  Object.assign(contactData.value, updatedData);
};

const open = () => {
  contactData.value = props.selectedContact
    ? { ...props.selectedContact }
    : {};
  dialogRef.value?.open?.();
};

const close = () => {
  dialogRef.value?.close?.();
};

const updateContact = async () => {
  try {
    const { customAttributes, ...basicContactData } = contactData.value;
    await store.dispatch('contacts/update', basicContactData);
    await store.dispatch(
      'contacts/fetchContactableInbox',
      props.selectedContact.id
    );
    useAlert(t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.SUCCESS_MESSAGE'));
    close();
  } catch (error) {
    useAlert(t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.ERROR_MESSAGE'));
  }
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    width="2xl"
    overflow-y-auto
    position="top"
    :title="t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.TITLE')"
    :confirm-button-label="
      t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.UPDATE_BUTTON')
    "
    :disable-confirm-button="isUpdating || isFormInvalid"
    :is-loading="isUpdating"
    @confirm="updateContact"
  >
    <ContactsForm
      ref="contactsFormRef"
      :contact-data="contactData"
      is-details-view
      @update="handleFormUpdate"
    />
  </Dialog>
</template>
