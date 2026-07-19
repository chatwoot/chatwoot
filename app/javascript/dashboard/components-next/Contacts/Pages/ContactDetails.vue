<script setup>
import { ref } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import ContactDetailProfileCard from 'dashboard/components-next/Contacts/ContactDetailProfileCard.vue';
import ContactInfoReadOnly from 'dashboard/components-next/Contacts/ContactInfoReadOnly.vue';
import ContactEditDialog from 'dashboard/components-next/Contacts/ContactEditDialog.vue';

const props = defineProps({
  selectedContact: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();

const editDialogRef = ref(null);
const avatarFile = ref(null);

const openEdit = () => {
  editDialogRef.value?.open?.();
};

const handleAssigneeUpdate = () => {};

const handleAvatarUpload = async ({ file }) => {
  avatarFile.value = file;

  try {
    await store.dispatch('contacts/update', {
      id: props.selectedContact.id,
      avatar: file,
      isFormData: true,
    });
    useAlert(t('CONTACTS_LAYOUT.DETAILS.AVATAR.UPLOAD.SUCCESS_MESSAGE'));
  } catch {
    useAlert(t('CONTACTS_LAYOUT.DETAILS.AVATAR.UPLOAD.ERROR_MESSAGE'));
  }
};

const handleAvatarDelete = async () => {
  try {
    if (props.selectedContact?.id) {
      await store.dispatch('contacts/deleteAvatar', props.selectedContact.id);
      useAlert(t('CONTACTS_LAYOUT.DETAILS.AVATAR.DELETE.SUCCESS_MESSAGE'));
    }
    avatarFile.value = null;
  } catch (error) {
    useAlert(
      error.message
        ? error.message
        : t('CONTACTS_LAYOUT.DETAILS.AVATAR.DELETE.ERROR_MESSAGE')
    );
  }
};

defineExpose({ openEdit });
</script>

<template>
  <div class="flex flex-col gap-4">
    <ContactDetailProfileCard
      :selected-contact="selectedContact"
      @update="handleAssigneeUpdate"
      @upload="handleAvatarUpload"
      @delete-avatar="handleAvatarDelete"
    />

    <ContactInfoReadOnly :selected-contact="selectedContact" />

    <ContactEditDialog
      ref="editDialogRef"
      :selected-contact="selectedContact"
    />
  </div>
</template>
