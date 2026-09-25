<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import camelcaseKeys from 'camelcase-keys';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator';
import ContactAPI from 'dashboard/api/contacts';

import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import CompanyConversationFilters from 'dashboard/components-next/Companies/CompanyDetail/CompanyConversationFilters.vue';
import CompanyConversationList from 'dashboard/components-next/Companies/CompanyDetail/CompanyConversationList.vue';
import CompanyNotesFeed from 'dashboard/components-next/Companies/CompanyDetail/CompanyNotesFeed.vue';
import CompanySearchInput from 'dashboard/components-next/Companies/CompanyDetail/CompanySearchInput.vue';
import ConfirmContactDeleteDialog from 'dashboard/components-next/Contacts/ContactsForm/ConfirmContactDeleteDialog.vue';
import ContactDetailHeader from 'dashboard/components-next/Contacts/ContactDetail/ContactDetailHeader.vue';
import ContactEditPanel from 'dashboard/components-next/Contacts/ContactDetail/ContactEditPanel.vue';
import ContactFacts from 'dashboard/components-next/Contacts/ContactDetail/ContactFacts.vue';
import ContactNoteComposer from 'dashboard/components-next/Contacts/ContactDetail/ContactNoteComposer.vue';
import ContactMedia from 'dashboard/components-next/Contacts/ContactsSidebar/ContactMedia.vue';
import ContactMerge from 'dashboard/components-next/Contacts/ContactsSidebar/ContactMerge.vue';

const { t } = useI18n();
const store = useStore();
const route = useRoute();
const router = useRouter();

const contactById = useMapGetter('contacts/getContactById');
const uiFlags = useMapGetter('contacts/getUIFlags');
const notesByContact = useMapGetter('contactNotes/getAllNotesByContactId');
const notesUIFlags = useMapGetter('contactNotes/getUIFlags');

const editPanelRef = ref(null);
const mergeDialogRef = ref(null);
const confirmDeleteDialogRef = ref(null);
const tabsRef = ref(null);

const TAB_VALUES = ['conversations', 'notes', 'media'];
const activeTab = computed(() =>
  TAB_VALUES.includes(route.query.tab) ? route.query.tab : TAB_VALUES[0]
);
const setActiveTab = tab => {
  if (tab === activeTab.value) return;
  router.replace({ query: { tab } });
};

const contactId = computed(() => Number(route.params.contactId));
const contact = computed(() => contactById.value(contactId.value));
const hasContact = computed(() => Boolean(contact.value?.id));
const showInitialLoadingState = computed(
  () => !hasContact.value && uiFlags.value.isFetchingItem
);

// Conversations stay in the API shape so the shared conversation cards can render them.
const conversations = ref([]);
const conversationsMeta = ref({});
const isFetchingConversations = ref(false);
let conversationsRequestToken = 0;

const openConversationsCount = computed(() =>
  Number(conversationsMeta.value.openCount || 0)
);
const hasMoreConversations = computed(
  () =>
    conversations.value.length < Number(conversationsMeta.value.totalCount || 0)
);

const fetchConversations = async (page = 1, filters = []) => {
  conversationsRequestToken += 1;
  const requestToken = conversationsRequestToken;
  isFetchingConversations.value = true;
  try {
    const {
      data: { payload, meta },
    } = filters.length
      ? await ContactAPI.filterConversations(
          contactId.value,
          filterQueryGenerator(useSnakeCase(filters)).payload,
          page
        )
      : await ContactAPI.getConversations(contactId.value, { page });
    if (requestToken !== conversationsRequestToken) return;

    conversations.value =
      page > 1 ? [...conversations.value, ...payload] : payload;
    conversationsMeta.value = camelcaseKeys(meta || {});
  } catch {
    if (requestToken === conversationsRequestToken) {
      useAlert(t('CONTACTS_LAYOUT.DETAIL.CONVERSATIONS.FETCH_ERROR'));
    }
  } finally {
    if (requestToken === conversationsRequestToken) {
      isFetchingConversations.value = false;
    }
  }
};

// ConversationFilter conditions live in the URL so returning from a conversation restores them.
const parseConversationFilters = value => {
  try {
    return value ? JSON.parse(value) : [];
  } catch {
    return [];
  }
};
const conversationFilters = computed({
  get: () =>
    activeTab.value === 'conversations'
      ? parseConversationFilters(route.query.filters)
      : [],
  set: filters => {
    router.replace({
      query: {
        tab: 'conversations',
        filters: filters.length ? JSON.stringify(filters) : undefined,
      },
    });
    fetchConversations(1, filters);
  },
});

const loadMoreConversations = () =>
  fetchConversations(
    Number(conversationsMeta.value.page || 1) + 1,
    conversationFilters.value
  );

const showOpenConversations = () => {
  conversationFilters.value = [
    {
      attributeKey: 'status',
      filterOperator: 'equal_to',
      values: [
        { id: 'open', name: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.open.TEXT') },
      ],
      queryOperator: 'and',
    },
  ];
  tabsRef.value?.scrollIntoView({ behavior: 'smooth', block: 'start' });
};

// A contact's notes are few enough to load at once and search in place.
const notesQuery = ref(route.query.tab === 'notes' ? route.query.q || '' : '');
const notesSearch = computed(() => notesQuery.value.trim());
const notes = computed(() => notesByContact.value(contactId.value));
const filteredNotes = computed(() => {
  const term = notesSearch.value.toLowerCase();
  if (!term) return notes.value;
  return notes.value.filter(note =>
    (note.content || '').toLowerCase().includes(term)
  );
});

watch(notesSearch, q => {
  router.replace({ query: { tab: 'notes', q: q || undefined } });
});

const deleteNote = noteId =>
  store.dispatch('contactNotes/delete', { noteId, contactId: contactId.value });

const tabs = computed(() => [
  {
    value: 'conversations',
    icon: 'i-lucide-message-circle',
    label: t('CONTACTS_LAYOUT.DETAIL.TABS.CONVERSATIONS'),
    count: Number(conversationsMeta.value.allCount || 0),
  },
  {
    value: 'notes',
    icon: 'i-lucide-notebook-pen',
    label: t('CONTACTS_LAYOUT.DETAIL.TABS.NOTES'),
    count: notes.value.length,
  },
  {
    value: 'media',
    icon: 'i-lucide-images',
    label: t('CONTACTS_LAYOUT.DETAIL.TABS.MEDIA'),
  },
]);

const activeTabIndex = computed(() =>
  tabs.value.findIndex(tab => tab.value === activeTab.value)
);

const goToContactsList = () => {
  if (window.history.state?.back) {
    router.back();
    return;
  }
  router.push({
    name: 'contacts_dashboard_index',
    params: { accountId: route.params.accountId },
    query: { page: '1' },
  });
};

const toggleContactBlock = async () => {
  const isBlocked = contact.value.blocked;
  try {
    await store.dispatch('contacts/update', {
      id: contact.value.id,
      blocked: !isBlocked,
    });
    useAlert(
      isBlocked
        ? t('CONTACTS_LAYOUT.HEADER.ACTIONS.UNBLOCK_SUCCESS_MESSAGE')
        : t('CONTACTS_LAYOUT.HEADER.ACTIONS.BLOCK_SUCCESS_MESSAGE')
    );
  } catch {
    useAlert(
      isBlocked
        ? t('CONTACTS_LAYOUT.HEADER.ACTIONS.UNBLOCK_ERROR_MESSAGE')
        : t('CONTACTS_LAYOUT.HEADER.ACTIONS.BLOCK_ERROR_MESSAGE')
    );
  }
};

watch(
  contactId,
  id => {
    conversations.value = [];
    conversationsMeta.value = {};
    if (!id) return;
    store.dispatch('contacts/show', { id });
    store.dispatch('contacts/fetchContactableInbox', id);
    store.dispatch('contactNotes/get', { contactId: id });
    store.dispatch('attributes/get');
    fetchConversations(1, conversationFilters.value);
  },
  { immediate: true }
);
</script>

<template>
  <section class="w-full h-full overflow-y-auto bg-n-surface-1">
    <div class="flex flex-col w-full max-w-5xl gap-8 px-6 pt-6 pb-24 mx-auto">
      <Button
        :label="t('CONTACTS_LAYOUT.HEADER.TITLE')"
        icon="i-lucide-arrow-left"
        variant="link"
        color="slate"
        size="sm"
        class="self-start -mb-4"
        @click="goToContactsList"
      />

      <div
        v-if="showInitialLoadingState || uiFlags.isMerging"
        class="flex justify-center py-24 text-n-slate-11"
      >
        <Spinner />
      </div>

      <div v-else-if="!hasContact" class="flex flex-col gap-2 py-24">
        <span class="text-lg font-medium text-n-slate-12">
          {{ t('CONTACTS_LAYOUT.DETAIL.EMPTY_STATE.TITLE') }}
        </span>
        <p class="max-w-md text-sm text-n-slate-11">
          {{ t('CONTACTS_LAYOUT.DETAIL.EMPTY_STATE.SUBTITLE') }}
        </p>
      </div>

      <template v-else>
        <section class="border rounded-xl border-n-weak bg-n-solid-1">
          <div class="flex flex-col gap-5 p-6">
            <ContactDetailHeader
              :contact="contact"
              :open-conversations-count="openConversationsCount"
              @edit="editPanelRef?.open()"
              @merge="mergeDialogRef?.open()"
              @delete="confirmDeleteDialogRef?.dialogRef.open()"
              @toggle-block="toggleContactBlock"
              @show-open-conversations="showOpenConversations"
            />
            <ContactFacts :contact="contact" />
          </div>
        </section>

        <div class="flex flex-col gap-4">
          <div
            ref="tabsRef"
            class="sticky top-0 z-10 flex flex-wrap items-center justify-between gap-3 py-3 border-b bg-n-surface-1 border-n-weak"
          >
            <TabBar
              :tabs="tabs"
              :initial-active-tab="activeTabIndex"
              @tab-changed="tab => setActiveTab(tab.value)"
            />
            <CompanyConversationFilters
              v-if="activeTab === 'conversations'"
              v-model="conversationFilters"
              class="ms-auto"
            />
            <CompanySearchInput
              v-else-if="activeTab === 'notes'"
              v-model="notesQuery"
              :placeholder="t('CONTACTS_LAYOUT.DETAIL.NOTES.SEARCH')"
            />
          </div>

          <CompanyConversationList
            v-if="activeTab === 'conversations'"
            :conversations="conversations"
            :filtered="conversationFilters.length > 0"
            :is-loading="isFetchingConversations"
            :has-more="hasMoreConversations"
            :empty-message="t('CONTACTS_LAYOUT.DETAIL.CONVERSATIONS.EMPTY')"
            @load-more="loadMoreConversations"
          />
          <div v-else-if="activeTab === 'notes'" class="flex flex-col gap-4">
            <ContactNoteComposer v-if="!notesSearch" :contact-id="contactId" />
            <CompanyNotesFeed
              :notes="filteredNotes"
              :is-loading="notesUIFlags.isFetching"
              :empty-message="
                notesSearch
                  ? t('CONTACTS_LAYOUT.DETAIL.NOTES.NO_MATCHES')
                  : t('CONTACTS_LAYOUT.SIDEBAR.NOTES.EMPTY_STATE')
              "
              :highlight="notesSearch"
              deletable
              @delete="deleteNote"
            />
          </div>
          <ContactMedia v-else class="!px-0" />
        </div>

        <ContactEditPanel ref="editPanelRef" :contact="contact" />

        <Dialog
          ref="mergeDialogRef"
          :show-cancel-button="false"
          :show-confirm-button="false"
          width="xl"
        >
          <ContactMerge
            :selected-contact="contact"
            class="!px-0"
            @go-to-contacts-list="goToContactsList"
            @reset-tab="mergeDialogRef?.close()"
          />
        </Dialog>
      </template>
    </div>

    <ConfirmContactDeleteDialog
      ref="confirmDeleteDialogRef"
      :selected-contact="contact"
      @go-to-contacts-list="goToContactsList"
    />
  </section>
</template>
