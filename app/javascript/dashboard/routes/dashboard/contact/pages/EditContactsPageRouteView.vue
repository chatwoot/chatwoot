<script setup>
import { onMounted, computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRoute, useRouter } from 'vue-router';

import ContactsLayout from 'dashboard/components-next/Contacts/ContactsLayout.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ContactDetails from 'dashboard/components-next/Contacts/Pages/ContactDetails.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import ContactNotes from 'dashboard/components-next/Contacts/ContactsSidebar/ContactNotes.vue';
// import ContactHistory from 'dashboard/components-next/Contacts/ContactsSidebar/ContactHistory.vue';

const store = useStore();
const route = useRoute();
const router = useRouter();

const contact = useMapGetter('contacts/getContact');
const uiFlags = useMapGetter('contacts/getUIFlags');

const activeTab = ref('notes');

const isFetchingItem = computed(() => uiFlags.value.isFetchingItem);

const selectedContact = computed(() => contact.value(route.params.contactId));

const { t } = useI18n();

const CONTACT_TABS_OPTIONS = [
  { key: 'ATTRIBUTES', value: 'attributes' },
  { key: 'HISTORY', value: 'history' },
  { key: 'NOTES', value: 'notes' },
  { key: 'MERGE', value: 'merge' },
];

const tabs = computed(() => {
  return CONTACT_TABS_OPTIONS.map(tab => ({
    label: t(`CONTACTS_LAYOUT.SIDEBAR.TABS.${tab.key}`),
    value: tab.value,
  }));
});

const activeTabIndex = computed(() => {
  return CONTACT_TABS_OPTIONS.findIndex(v => v.value === activeTab.value);
});

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

const handleTabChange = tab => {
  activeTab.value = tab.value;
};

const fetchContactNotes = () => {
  const { contactId } = route.params;
  if (contactId) store.dispatch('contactNotes/get', { contactId });
};

const fetchContactConversations = () => {
  const { contactId } = route.params;
  if (contactId) store.dispatch('contactConversations/get', contactId);
};

onMounted(() => {
  fetchActiveContact();
  fetchContactNotes();
  fetchContactConversations();
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
      <template #sidebar>
        <div class="px-6">
          <TabBar
            :tabs="tabs"
            :initial-active-tab="activeTabIndex"
            class="w-full [&>button]:w-full bg-n-alpha-black2"
            @tab-changed="handleTabChange"
          />
        </div>
        <ContactNotes v-if="activeTab === 'notes'" />
        <!-- <ContactHistory v-if="activeTab === 'history'" /> -->
      </template>
    </ContactsLayout>
  </div>
</template>
