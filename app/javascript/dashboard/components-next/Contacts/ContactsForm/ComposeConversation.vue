<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
// import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import camelcaseKeys from 'camelcase-keys';

import ContactAPI from 'dashboard/api/contacts';
import { debounce } from '@chatwoot/utils';

import ComposeNewConversation from 'dashboard/components-next/NewConversation/ComposeNewConversation.vue';

const route = useRoute();
const { t } = useI18n();

const contacts = ref([]);
const isSearching = ref(false);
const showComposeNewConversation = ref(false);

const contactId = computed(() => route.params.contactId || null);

const generateContactQuery = ({ query }) => {
  return {
    payload: [
      {
        attribute_key: 'email',
        filter_operator: 'contains',
        values: [query],
        attribute_model: 'standard',
        custom_attribute_type: '',
      },
    ],
  };
};

const onContactSearch = debounce(
  async query => {
    isSearching.value = true;
    contacts.value = [];
    try {
      const {
        data: { payload },
      } = await ContactAPI.filter(
        undefined,
        'name',
        generateContactQuery({ query })
      );
      contacts.value = camelcaseKeys(payload, { deep: true });
      isSearching.value = false;
    } catch (error) {
      useAlert(t('CONTACTS_LAYOUT.SIDEBAR.MERGE.SEARCH_ERROR_MESSAGE'));
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
