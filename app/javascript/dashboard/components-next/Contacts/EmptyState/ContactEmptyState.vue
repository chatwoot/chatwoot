<script setup>
import { ref } from 'vue';

import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import CreateNewContactDialog from 'dashboard/components-next/Contacts/ContactsForm/CreateNewContactDialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ContactsCard from 'dashboard/components-next/Contacts/ContactsCard/ContactsCard.vue';
import contactContent from 'dashboard/components-next/Contacts/EmptyState/contactEmptyStateContent';

defineProps({
  title: {
    type: String,
    default: '',
  },
  subtitle: {
    type: String,
    default: '',
  },
  showButton: {
    type: Boolean,
    default: true,
  },
  buttonLabel: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['create']);

const createNewContactDialogRef = ref(null);

const onClick = () => {
  createNewContactDialogRef.value?.dialogRef.open();
};
</script>

<template>
  <EmptyStateLayout :title="title" :subtitle="subtitle">
    <template #empty-state-item>
      <div class="grid grid-cols-1 gap-4 p-px overflow-hidden">
        <ContactsCard
          v-for="contact in contactContent.slice(0, 5)"
          :id="contact.id"
          :key="contact.id"
          :name="contact.name"
          :email="contact.email"
          :thumbnail="contact.thumbnail"
          :phone-number="contact.phoneNumber"
          :additional-attributes="contact.additionalAttributes"
          :is-expanded="0 === contact.id"
          @toggle="toggleExpanded(contact.id)"
        />
      </div>
    </template>
    <template #actions>
      <div v-if="showButton">
        <Button :label="buttonLabel" icon="i-lucide-plus" @click="onClick" />
        <CreateNewContactDialog
          ref="createNewContactDialogRef"
          @create="emit('create', $event)"
        />
      </div>
    </template>
  </EmptyStateLayout>
</template>
