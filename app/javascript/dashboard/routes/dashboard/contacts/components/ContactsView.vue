<template>
  <div class="contacts-page">
    <contacts-header />
    <contacts />
  </div>
</template>

<script>
import ContactsHeader from './Header';
import Contacts from './Contacts';

export default {
  components: {
    ContactsHeader,
    Contacts,
  },
};
</script>

<style lang="scss" scoped>
.contacts-page {
  padding-top: var(--space-normal);
}
</style>
