<script setup>
import { ref, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ContactsForm from 'dashboard/components-next/Contacts/ContactsForm/ContactsForm.vue';

const emit = defineEmits(['create']);

const { t } = useI18n();

const dialogRef = ref(null);
const contactsFormRef = ref(null);
const contact = ref(null);

const uiFlags = useMapGetter('contacts/getUIFlags');
const isCreatingContact = computed(() => uiFlags.value.isCreating);

const createNewContact = contactItem => {
  contact.value = contactItem;
};

const handleDialogConfirm = async () => {
  if (!contact.value) return;
  emit('create', contact.value);
};

const onSuccess = () => {
  contactsFormRef.value?.resetForm();
  dialogRef.value.close();
};

const closeDialog = () => {
  dialogRef.value.close();
};

defineExpose({ dialogRef, contactsFormRef, onSuccess });
</script>

<template>
  <Dialog ref="dialogRef" width="3xl" @confirm="handleDialogConfirm">
    <ContactsForm
      ref="contactsFormRef"
      is-new-contact
      @update="createNewContact"
    />
    <template #footer>
      <div class="flex items-center justify-between w-full gap-3">
        <Button
          :label="t('DIALOG.BUTTONS.CANCEL')"
          variant="link"
          type="reset"
          class="h-10 hover:!no-underline hover:text-n-brand"
          @click="closeDialog"
        />
        <Button
          type="submit"
          :label="
            t('CONTACTS_LAYOUT.HEADER.ACTIONS.CONTACT_CREATION.SAVE_CONTACT')
          "
          color="blue"
          :disabled="contactsFormRef?.isFormInvalid"
          :is-loading="isCreatingContact"
        />
      </div>
    </template>
  </Dialog>
</template>
