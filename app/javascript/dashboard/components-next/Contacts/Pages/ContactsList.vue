<script setup>
import { ref, computed } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useRouter, useRoute } from 'vue-router';
import {
  DuplicateContactException,
  ExceptionWithMessage,
} from 'shared/helpers/CustomErrors';
import ContactsCard from 'dashboard/components-next/Contacts/ContactsCard/ContactsCard.vue';

defineProps({ contacts: { type: Array, required: true } });

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const route = useRoute();

const uiFlags = useMapGetter('contacts/getUIFlags');
const isUpdating = computed(() => uiFlags.value.isUpdating);
const expandedCardId = ref(null);

const updateContact = async updatedData => {
  try {
    await store.dispatch('contacts/update', updatedData);
    useAlert(t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.SUCCESS_MESSAGE'));
  } catch (error) {
    const i18nPrefix = 'CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.FORM';
    if (error instanceof DuplicateContactException) {
      if (error.data.includes('email')) {
        useAlert(t(`${i18nPrefix}.EMAIL_ADDRESS.DUPLICATE`));
      } else if (error.data.includes('phone_number')) {
        useAlert(t(`${i18nPrefix}.PHONE_NUMBER.DUPLICATE`));
      }
    } else if (error instanceof ExceptionWithMessage) {
      useAlert(error.data);
    } else {
      useAlert(t(`${i18nPrefix}.ERROR_MESSAGE`));
    }
  }
};

const onClickViewDetails = async id => {
  const routeTypes = {
    contacts_dashboard_segments_index: ['contacts_edit_segment', 'segmentId'],
    contacts_dashboard_labels_index: ['contacts_edit_label', 'label'],
  };
  const [name, paramKey] = routeTypes[route.name] || ['contacts_edit'];
  const params = {
    contactId: id,
    ...(paramKey && { [paramKey]: route.params[paramKey] }),
  };

  await router.push({ name, params, query: route.query });
};

const toggleExpanded = id => {
  expandedCardId.value = expandedCardId.value === id ? null : id;
};
</script>

<template>
  <div class="flex flex-col gap-4 px-6 pt-4 pb-6">
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
      :is-updating="isUpdating"
      @toggle="toggleExpanded(contact.id)"
      @update-contact="updateContact"
      @show-contact="onClickViewDetails"
    />
  </div>
</template>
