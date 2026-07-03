<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import ConfirmContactDeleteDialog from 'dashboard/components-next/Contacts/ContactsForm/ConfirmContactDeleteDialog.vue';
import ContactMergeDialog from 'dashboard/components-next/Contacts/ContactMergeDialog.vue';
import { usePolicy } from 'dashboard/composables/usePolicy';

defineProps({
  selectedContact: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['goToContactsList']);

const { t } = useI18n();
const { checkPermissions } = usePolicy();

const showActionsDropdown = ref(false);
const confirmDeleteContactDialogRef = ref(null);
const contactMergeDialogRef = ref(null);

const isAdmin = computed(() => checkPermissions(['administrator']));

const menuItems = computed(() => {
  const items = [
    {
      label: t('CONTACTS_LAYOUT.DETAILS.MORE_ACTIONS.MERGE'),
      action: 'merge',
      value: 'merge',
      icon: 'i-lucide-git-merge',
    },
  ];

  if (isAdmin.value) {
    items.push({
      label: t('CONTACTS_LAYOUT.DETAILS.MORE_ACTIONS.DELETE'),
      action: 'delete',
      value: 'delete',
      icon: 'i-lucide-trash-2',
    });
  }

  return items;
});

const handleContactAction = ({ action }) => {
  showActionsDropdown.value = false;

  if (action === 'merge') {
    contactMergeDialogRef.value?.open?.();
  } else if (action === 'delete') {
    confirmDeleteContactDialogRef.value?.dialogRef.open();
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
      :menu-items="menuItems"
      class="ltr:right-0 rtl:left-0 mt-1 w-52 top-full"
      @action="handleContactAction($event)"
    />

    <ContactMergeDialog
      ref="contactMergeDialogRef"
      :selected-contact="selectedContact"
      @go-to-contacts-list="emit('goToContactsList')"
    />

    <ConfirmContactDeleteDialog
      v-if="isAdmin"
      ref="confirmDeleteContactDialogRef"
      :selected-contact="selectedContact"
      @go-to-contacts-list="emit('goToContactsList')"
    />
  </div>
</template>
