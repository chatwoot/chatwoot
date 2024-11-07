<script setup>
import { ref } from 'vue';

import ContactsCard from 'dashboard/components-next/Contacts/ContactsCard/ContactsCard.vue';

defineProps({
  contacts: {
    type: Array,
    required: true,
  },
});

// Manage expanded state here
const expandedCardId = ref(null);

const toggleExpanded = id => {
  expandedCardId.value = expandedCardId.value === id ? null : id;
};
</script>

<template>
  <div class="flex flex-col gap-4">
    <ContactsCard
      v-for="contact in contacts"
      :id="contact.id"
      :key="contact.id"
      :name="contact.name"
      :email="contact.email"
      :thumbnail="contact.thumbnail"
      :phone-number="contact.phoneNumber"
      :additional-attributes="contact.additionalAttributes"
      :is-expanded="expandedCardId === contact.id"
      @toggle="toggleExpanded(contact.id)"
    />
  </div>
</template>
