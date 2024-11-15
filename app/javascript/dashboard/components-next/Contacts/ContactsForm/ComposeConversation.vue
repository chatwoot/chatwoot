<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { debounce } from '@chatwoot/utils';
import { searchContacts } from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper.js';

import ComposeNewConversation from 'dashboard/components-next/NewConversation/ComposeNewConversation.vue';

const route = useRoute();
const { t } = useI18n();

const contacts = ref([]);
const isSearching = ref(false);
const showComposeNewConversation = ref(false);

const contactId = computed(() => route.params.contactId || null);

const onContactSearch = debounce(
  async query => {
    isSearching.value = true;
    contacts.value = [];
    try {
      contacts.value = await searchContacts(query);
      isSearching.value = false;
    } catch (error) {
      useAlert(t('COMPOSE_NEW_CONVERSATION.CONTACT_SEARCH.ERROR_MESSAGE'));
    } finally {
      isSearching.value = false;
    }
  },
  300,
  false
);

const toggle = () => {
  showComposeNewConversation.value = !showComposeNewConversation.value;
};

const closeCompose = () => {
  showComposeNewConversation.value = false;
};
</script>

<template>
  <div class="relative">
    <slot
      name="trigger"
      :is-open="showComposeNewConversation"
      :toggle="toggle"
    />

    <ComposeNewConversation
      v-if="showComposeNewConversation"
      :contacts="contacts"
      :contact-id="contactId"
      :is-loading="isSearching"
      @search-contacts="onContactSearch"
      @discard="closeCompose"
    />
  </div>
</template>
