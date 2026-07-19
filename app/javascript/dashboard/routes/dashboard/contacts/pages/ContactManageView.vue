<script setup>
import { onMounted, computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRoute, useRouter } from 'vue-router';

import ContactsDetailsLayout from 'dashboard/components-next/Contacts/ContactsDetailsLayout.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ContactDetails from 'dashboard/components-next/Contacts/Pages/ContactDetails.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import ContactNotes from 'dashboard/components-next/Contacts/ContactsSidebar/ContactNotes.vue';
import ContactHistory from 'dashboard/components-next/Contacts/ContactsSidebar/ContactHistory.vue';
import ContactMedia from 'dashboard/components-next/Contacts/ContactsSidebar/ContactMedia.vue';
import ContactCustomAttributes from 'dashboard/components-next/Contacts/ContactsSidebar/ContactCustomAttributes.vue';
import ContactConversationMetrics from 'dashboard/components-next/Contacts/ContactConversationMetrics.vue';

const store = useStore();
const route = useRoute();
const router = useRouter();

const contact = useMapGetter('contacts/getContactById');
const uiFlags = useMapGetter('contacts/getUIFlags');
const notesByContact = useMapGetter('contactNotes/getAllNotesByContactId');

const activeActivityTab = ref('history');
const contactDetailsRef = ref(null);

const isFetchingItem = computed(() => uiFlags.value.isFetchingItem);
const isMergingContact = computed(() => uiFlags.value.isMerging);
const isUpdatingContact = computed(() => uiFlags.value.isUpdating);

const selectedContact = computed(() => contact.value(route.params.contactId));

const showSpinner = computed(
  () => isFetchingItem.value || isMergingContact.value
);

const notesCount = computed(
  () => notesByContact.value(route.params.contactId)?.length || 0
);

const { t } = useI18n();

const ACTIVITY_TABS = [
  { key: 'HISTORY', value: 'history' },
  { key: 'MEDIA', value: 'media' },
];

const activityTabs = computed(() =>
  ACTIVITY_TABS.map(tab => ({
    label: t(`CONTACTS_LAYOUT.SIDEBAR.TABS.${tab.key}`),
    value: tab.value,
    count:
      tab.value === 'history'
        ? selectedContact.value?.conversationsCount
        : undefined,
  }))
);

const activeActivityTabIndex = computed(() =>
  ACTIVITY_TABS.findIndex(v => v.value === activeActivityTab.value)
);

const goToContactsList = () => {
  if (window.history.state?.back || window.history.length > 1) {
    router.back();
  } else {
    router.push(`/app/accounts/${route.params.accountId}/contacts?page=1`);
  }
};

const fetchActiveContact = async () => {
  if (route.params.contactId) {
    await store.dispatch('contacts/show', { id: route.params.contactId });
    await store.dispatch(
      'contacts/fetchContactableInbox',
      route.params.contactId
    );
  }
};

const handleActivityTabChange = tab => {
  activeActivityTab.value = tab.value;
};

const openEditContact = () => {
  contactDetailsRef.value?.openEdit?.();
};

const fetchContactNotes = () => {
  const { contactId } = route.params;
  if (contactId) store.dispatch('contactNotes/get', { contactId });
};

const fetchContactConversations = () => {
  const { contactId } = route.params;
  if (contactId) store.dispatch('contactConversations/get', contactId);
};

const fetchAttributes = () => {
  store.dispatch('attributes/get');
};

const toggleContactBlock = async isBlocked => {
  const ALERT_MESSAGES = {
    success: {
      block: t('CONTACTS_LAYOUT.HEADER.ACTIONS.BLOCK_SUCCESS_MESSAGE'),
      unblock: t('CONTACTS_LAYOUT.HEADER.ACTIONS.UNBLOCK_SUCCESS_MESSAGE'),
    },
    error: {
      block: t('CONTACTS_LAYOUT.HEADER.ACTIONS.BLOCK_ERROR_MESSAGE'),
      unblock: t('CONTACTS_LAYOUT.HEADER.ACTIONS.UNBLOCK_ERROR_MESSAGE'),
    },
  };

  try {
    await store.dispatch(`contacts/update`, {
      ...selectedContact.value,
      blocked: !isBlocked,
    });
    useAlert(
      isBlocked ? ALERT_MESSAGES.success.unblock : ALERT_MESSAGES.success.block
    );
  } catch (error) {
    useAlert(
      isBlocked ? ALERT_MESSAGES.error.unblock : ALERT_MESSAGES.error.block
    );
  }
};

onMounted(() => {
  fetchActiveContact();
  fetchContactNotes();
  fetchContactConversations();
  fetchAttributes();
});
</script>

<template>
  <div
    class="flex flex-col justify-between flex-1 w-full min-w-0 h-full m-0 overflow-auto bg-n-surface-1"
  >
    <ContactsDetailsLayout
      :selected-contact="selectedContact"
      :is-updating="isUpdatingContact"
      @go-to-contacts-list="goToContactsList"
      @toggle-block="toggleContactBlock"
      @edit="openEditContact"
    >
      <div
        v-if="showSpinner"
        class="flex items-center justify-center py-10 text-n-slate-11"
      >
        <Spinner />
      </div>
      <div
        v-else-if="selectedContact"
        class="flex flex-col gap-6 pb-6"
      >
        <!-- Identity + contact fields + socials -->
        <ContactDetails
          ref="contactDetailsRef"
          :selected-contact="selectedContact"
        />

        <!-- Conversation metrics under profile -->
        <ContactConversationMetrics :selected-contact="selectedContact" />

        <div class="grid grid-cols-1 gap-6 xl:grid-cols-2 xl:gap-8">
          <!-- Left: attributes + notes (who / internal context) -->
          <div class="flex flex-col gap-6 min-w-0">
            <section class="flex flex-col gap-3">
              <h4 class="text-sm font-medium text-n-slate-12 px-1">
                {{ t('CONTACTS_LAYOUT.SIDEBAR.TABS.ATTRIBUTES') }}
              </h4>
              <div
                class="rounded-xl border border-n-weak bg-n-alpha-1 dark:bg-n-solid-2 p-3 sm:p-4"
              >
                <ContactCustomAttributes
                  :selected-contact="selectedContact"
                  compact
                />
              </div>
            </section>

            <section class="flex flex-col gap-3">
              <div class="flex items-center justify-between gap-2 px-1">
                <h4 class="text-sm font-medium text-n-slate-12">
                  {{ t('CONTACTS_LAYOUT.SIDEBAR.TABS.NOTES') }}
                </h4>
                <span
                  v-if="notesCount"
                  class="text-xs text-n-slate-10 tabular-nums"
                >
                  {{ notesCount }}
                </span>
              </div>
              <div
                class="rounded-xl border border-n-weak bg-n-alpha-1 dark:bg-n-solid-2 p-3 sm:p-4"
              >
                <ContactNotes compact />
              </div>
            </section>
          </div>

          <!-- Right: conversations + media (what happened) -->
          <div class="flex flex-col gap-3 min-w-0">
            <h4 class="text-sm font-medium text-n-slate-12 px-1">
              {{ t('CONTACTS_LAYOUT.DETAILS.SECTIONS.ACTIVITY') }}
            </h4>
            <div
              class="rounded-xl border border-n-weak bg-n-alpha-1 dark:bg-n-solid-2 overflow-hidden flex flex-col min-h-[28rem]"
            >
              <div class="px-4 pt-4 pb-2">
                <TabBar
                  :tabs="activityTabs"
                  :initial-active-tab="activeActivityTabIndex"
                  class="w-full [&>button]:w-full bg-n-alpha-black2"
                  @tab-changed="handleActivityTabChange"
                />
              </div>
              <div class="flex-1 min-h-0 overflow-y-auto px-2 pb-4 pt-2">
                <ContactHistory v-if="activeActivityTab === 'history'" />
                <ContactMedia v-else-if="activeActivityTab === 'media'" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </ContactsDetailsLayout>
  </div>
</template>
