<script setup>
import ContactsCard from '../ContactsCard.vue';
import contacts from './fixtures';
</script>

<template>
  <Story
    title="Components/Contacts/ContactsCard"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="Default">
      <div class="flex flex-col p-4 divide-y divide-n-weak">
        <ContactsCard
          v-for="contact in contacts"
          :key="contact.id"
          v-bind="contact"
        />
      </div>
    </Variant>

    <Variant title="Selected">
      <div class="flex flex-col p-4">
        <ContactsCard v-bind="contacts[0]" selectable is-selected />
      </div>
    </Variant>

    <Variant title="Without Email and Phone">
      <div class="flex flex-col p-4">
        <ContactsCard v-bind="{ ...contacts[3], email: '', phoneNumber: '' }" />
      </div>
    </Variant>
  </Story>
</template>
