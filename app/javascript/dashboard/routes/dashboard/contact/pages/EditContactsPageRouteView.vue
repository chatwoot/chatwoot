<script setup>
import { onMounted, computed } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRoute, useRouter } from 'vue-router';

import ContactsLayout from 'dashboard/components-next/Contacts/ContactsLayout.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ContactDetails from 'dashboard/components-next/Contacts/Pages/ContactDetails.vue';

const store = useStore();
const route = useRoute();
const router = useRouter();

const contact = useMapGetter('contacts/getContact');
const uiFlags = useMapGetter('contacts/getUIFlags');

const isFetchingItem = computed(() => uiFlags.value.isFetchingItem);

const selectedContact = computed(() => contact.value(route.params.contactId));

const goToContactsList = () => {
  router.push({
    name: 'contacts_dashboard_index',
  });
};

const fetchActiveContact = async () => {
  if (route.params.contactId) {
    store.dispatch('contacts/show', { id: route.params.contactId });
  }
};

onMounted(() => {
  fetchActiveContact();
});
</script>

<template>
  <div
    class="flex flex-col justify-between flex-1 h-full m-0 overflow-auto bg-n-background"
  >
    <ContactsLayout
      :button-label="$t('CONTACTS_LAYOUT.HEADER.MESSAGE_BUTTON')"
      :selected-contact="selectedContact"
      is-detail-view
      :show-pagination-footer="false"
      @go-to-contacts-list="goToContactsList"
    >
      <div
        v-if="isFetchingItem"
        class="flex items-center justify-center py-10 text-n-slate-11"
      >
        <Spinner />
      </div>
      <ContactDetails
        v-else
        :selected-contact="selectedContact"
        @go-to-contacts-list="goToContactsList"
      />
    </ContactsLayout>
  </div>
</template>
