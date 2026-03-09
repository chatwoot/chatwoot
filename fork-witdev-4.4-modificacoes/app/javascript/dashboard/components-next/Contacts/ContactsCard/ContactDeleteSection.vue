<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';

import Button from 'dashboard/components-next/button/Button.vue';
import ConfirmContactDeleteDialog from 'dashboard/components-next/Contacts/ContactsForm/ConfirmContactDeleteDialog.vue';

defineProps({
  selectedContact: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const [showDeleteSection, toggleDeleteSection] = useToggle();
const confirmDeleteContactDialogRef = ref(null);

const openConfirmDeleteContactDialog = () => {
  confirmDeleteContactDialogRef.value?.dialogRef.open();
};
</script>

<template>
  <div class="flex flex-col items-start border-t border-n-strong px-6 py-5">
    <Button
      :label="t('CONTACTS_LAYOUT.DETAILS.DELETE_CONTACT')"
      sm
      link
      slate
      class="hover:!no-underline text-n-slate-12"
      icon="i-lucide-chevron-down"
      trailing-icon
      @click="toggleDeleteSection()"
    />

    <div
      class="transition-all duration-300 ease-in-out grid w-full overflow-hidden"
      :class="
        showDeleteSection
          ? 'grid-rows-[1fr] opacity-100 mt-2'
          : 'grid-rows-[0fr] opacity-0 mt-0'
      "
    >
      <div class="overflow-hidden min-h-0">
        <span class="inline-flex text-n-slate-11 text-sm items-center gap-1">
          {{ t('CONTACTS_LAYOUT.CARD.DELETE_CONTACT.MESSAGE') }}
          <Button
            :label="t('CONTACTS_LAYOUT.CARD.DELETE_CONTACT.BUTTON')"
            sm
            ruby
            link
            @click="openConfirmDeleteContactDialog()"
          />
        </span>
      </div>
    </div>
  </div>
  <ConfirmContactDeleteDialog
    ref="confirmDeleteContactDialogRef"
    :selected-contact="selectedContact"
  />
</template>
