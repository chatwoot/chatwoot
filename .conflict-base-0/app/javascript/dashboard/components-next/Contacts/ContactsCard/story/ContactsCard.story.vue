<script setup>
import { ref } from 'vue';

import ContactsCard from '../ContactsCard.vue';
import contacts from './fixtures';

const expandedCardId = ref(null);

const toggleExpanded = id => {
  expandedCardId.value = expandedCardId.value === id ? null : id;
};
</script>

<template>
  <Story
    title="Components/Contacts/ContactsCard"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="Default with expandable function">
      <div class="flex flex-col p-4">
        <ContactsCard
          v-bind="contacts[0]"
          :is-expanded="expandedCardId === contacts[0].id"
          @toggle="toggleExpanded(contacts[0].id)"
          @update-contact="() => {}"
          @show-contact="() => {}"
        />
      </div>
    </Variant>

    <Variant title="With Company Name and without phone number">
      <div class="flex flex-col p-4">
        <ContactsCard
          v-bind="{ ...contacts[1], phoneNumber: '' }"
          :is-expanded="false"
          @toggle="() => {}"
          @update-contact="() => {}"
          @show-contact="() => {}"
        />
      </div>
    </Variant>

    <Variant title="Expanded State">
      <div class="flex flex-col p-4">
        <ContactsCard
          v-bind="contacts[2]"
          is-expanded
          @toggle="() => {}"
          @update-contact="() => {}"
          @show-contact="() => {}"
        />
      </div>
    </Variant>

    <Variant title="Without Email and Phone">
      <div class="flex flex-col p-4">
        <ContactsCard
          v-bind="{ ...contacts[3], email: '', phoneNumber: '' }"
          :is-expanded="false"
          @toggle="() => {}"
          @update-contact="() => {}"
          @show-contact="() => {}"
        />
      </div>
    </Variant>
  </Story>
</template>
