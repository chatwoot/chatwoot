<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import CreateNewContactDialog from 'dashboard/components-next/Contacts/ContactsForm/CreateNewContactDialog.vue';
import ContactImportDialog from 'dashboard/components-next/Contacts/ContactHeader/ContactImportDialog.vue';
import ContactExportDialog from 'dashboard/components-next/Contacts/ContactHeader/ContactExportDialog.vue';

const { t } = useI18n();

const contactMenuItems = [
  {
    label: t('CONTACTS_LAYOUT.HEADER.ACTIONS.CONTACT_CREATION.ADD_CONTACT'),
    action: 'add',
    value: 'add',
    icon: 'i-lucide-plus',
  },
  {
    label: t('CONTACTS_LAYOUT.HEADER.ACTIONS.CONTACT_CREATION.EXPORT_CONTACT'),
    action: 'export',
    value: 'export',
    icon: 'i-lucide-upload',
  },
  {
    label: t('CONTACTS_LAYOUT.HEADER.ACTIONS.CONTACT_CREATION.IMPORT_CONTACT'),
    action: 'import',
    value: 'import',
    icon: 'i-lucide-download',
  },
];

const showActionsDropdown = ref(false);
const createNewContactDialogRef = ref(null);
const contactImportDialogRef = ref(null);
const contactExportDialogRef = ref(null);

const handleContactAction = ({ action }) => {
  if (action === 'add') {
    createNewContactDialogRef.value?.dialogRef.open();
  } else if (action === 'import') {
    contactImportDialogRef.value?.dialogRef.open();
  } else if (action === 'export') {
    contactExportDialogRef.value?.dialogRef.open();
  }
};
</script>

<template>
  <div v-on-clickaway="() => (showActionsDropdown = false)" class="relative">
    <Button
      icon="i-lucide-ellipsis-vertical"
      color="slate"
      variant="ghost"
      size="sm"
      :class="showActionsDropdown ? 'bg-n-alpha-2' : ''"
      @click="showActionsDropdown = !showActionsDropdown"
    />
    <DropdownMenu
      v-if="showActionsDropdown"
      :menu-items="contactMenuItems"
      class="right-0 mt-1 w-52 top-full"
      @action="handleContactAction($event)"
    />
  </div>
  <CreateNewContactDialog ref="createNewContactDialogRef" />
  <ContactImportDialog ref="contactImportDialogRef" />
  <ContactExportDialog ref="contactExportDialogRef" />
</template>
