<script setup>
import ContactEmptyState from './ContactEmptyState.vue';
</script>

<template>
  <Story
    title="Components/Contacts/EmptyState"
    :layout="{ type: 'grid', width: '900px' }"
  >
    <!-- Default Story -->
    <Variant title="Default">
      <ContactEmptyState
        title="No contacts found"
        subtitle="Create your first contact to get started"
        button-label="Add Contact"
      />
    </Variant>

    <!-- Without Button -->
    <Variant title="Without Button">
      <ContactEmptyState
        title="No contacts"
        subtitle="These are your current contacts"
        :show-button="false"
      />
    </Variant>
  </Story>
</template>
