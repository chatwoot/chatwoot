<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { debounce } from '@chatwoot/utils';
import { useRouter, useRoute } from 'vue-router';

import ContactsCard from 'dashboard/components-next/Contacts/ContactsCard/ContactsCard.vue';

defineProps({
  contacts: {
    type: Array,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const route = useRoute();

// Manage expanded state here
const expandedCardId = ref(null);

const updateContact = async ({ id, updatedData }) => {
  try {
    await store.dispatch('contacts/update', { id, ...updatedData });
  } catch (error) {
    useAlert(t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.ERROR_MESSAGE'));
  }
};

const handleFormUpdate = debounce(
  ({ id, updatedData }) => updateContact({ id, updatedData }),
  400,
  false
);

const ROUTE_MAPPINGS = {
  contacts_dashboard_labels_index: 'contacts_dashboard_labels_edit_index',
  contacts_dashboard_segments_index: 'contacts_dashboard_segments_edit_index',
};

const onClickViewDetails = async id => {
  const dynamicRouteName =
    ROUTE_MAPPINGS[route.name] || 'contacts_dashboard_edit_index';

  const params = { contactId: id };

  if (route.name.includes('segments')) {
    params.segmentId = route.params.segmentId;
  } else if (route.name.includes('labels')) {
    params.label = route.params.label;
  }

  await router.push({ name: dynamicRouteName, params, query: route.query });
};

const toggleExpanded = id => {
  expandedCardId.value = expandedCardId.value === id ? null : id;
};
</script>

<template>
  <div class="flex flex-col gap-4">
    <ContactsCard
      v-for="contact in contacts"
      :id="contact.id"
      :key="contact.id"
      :name="contact.name"
      :email="contact.email"
      :thumbnail="contact.thumbnail"
      :phone-number="contact.phoneNumber"
      :additional-attributes="contact.additionalAttributes"
      :is-expanded="expandedCardId === contact.id"
      @toggle="toggleExpanded(contact.id)"
      @update-contact="handleFormUpdate"
      @show-contact="onClickViewDetails"
    />
  </div>
</template>
