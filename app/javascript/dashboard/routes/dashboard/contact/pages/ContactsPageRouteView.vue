<script setup>
import { onMounted, computed } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';

import ContactsLayout from 'dashboard/components-next/Contacts/ContactsLayout.vue';
import ContactsList from 'dashboard/components-next/Contacts/Pages/ContactsList.vue';

const store = useStore();

const contacts = useMapGetter('contacts/getContacts');
const uiFlags = useMapGetter('contacts/getUIFlags');
const meta = useMapGetter('contacts/getMeta');

const currentPage = computed(() => Number(meta.value?.currentPage));
const totalItems = computed(() => meta.value?.count);

const fetchContacts = page => {
  store.dispatch('contacts/get', { page });
};

onMounted(() => {
  fetchContacts(1);
});

const updateCurrentPage = page => {
  fetchContacts(page);
};
</script>

<template>
  <div
    class="flex flex-col justify-between flex-1 h-full m-0 overflow-auto bg-n-background"
  >
    <ContactsLayout
      :header-title="$t('CONTACTS_LAYOUT.HEADER.TITLE')"
      :button-label="$t('CONTACTS_LAYOUT.HEADER.MESSAGE_BUTTON')"
      :current-page="currentPage"
      :total-items="totalItems"
      @update:current-page="updateCurrentPage"
    >
      <ContactsList :contacts="contacts" />
    </ContactsLayout>
  </div>
</template>
