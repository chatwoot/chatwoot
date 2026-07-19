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

import ContactsTable from 'dashboard/components-next/Contacts/ContactsTable/ContactsTable.vue';

const props = defineProps({
  contacts: { type: Array, required: true },

  selectedContactIds: {
    type: Array,

    default: () => [],
  },

  activeSort: { type: String, default: 'last_activity_at' },

  activeOrdering: { type: String, default: '' },
});

const emit = defineEmits(['toggleContact', 'update:sort']);

const { t } = useI18n();

const store = useStore();

const router = useRouter();

const route = useRoute();

const uiFlags = useMapGetter('contacts/getUIFlags');

const isUpdating = computed(() => uiFlags.value.isUpdating);

const expandedCardId = ref(null);

const hoveredAvatarId = ref(null);

const selectedIdsSet = computed(() => new Set(props.selectedContactIds || []));

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

const isSelected = id => selectedIdsSet.value.has(id);

const shouldShowSelection = id => {
  return hoveredAvatarId.value === id || isSelected(id);
};

const handleSelect = payload => {
  emit('toggleContact', payload);
};

const handleAvatarHover = (id, isHovered) => {
  hoveredAvatarId.value = isHovered ? id : null;
};

const handleSort = sortPayload => {
  emit('update:sort', sortPayload);
};
</script>

<template>
  <div class="flex flex-col flex-1 h-full min-h-0">
    <!-- Desktop: table view -->
    <ContactsTable
      :contacts="contacts"
      :selected-contact-ids="selectedContactIds"
      :active-sort="activeSort"
      :active-ordering="activeOrdering"
      class="hidden md:flex min-h-0 flex-1"
      @toggle-contact="handleSelect"
      @show-contact="onClickViewDetails"
      @update:sort="handleSort"
    />

    <!-- Mobile: card view -->
    <div class="flex min-h-0 flex-1 flex-col gap-3 overflow-y-auto md:hidden">
      <div v-for="contact in contacts" :key="contact.id" class="relative">
        <ContactsCard
          :id="contact.id"
          :name="contact.name"
          :email="contact.email"
          :document-number="contact.documentNumber"
          :company-id="contact.companyId"
          :thumbnail="contact.thumbnail"
          :phone-number="contact.phoneNumber"
          :additional-attributes="contact.additionalAttributes"
          :custom-attributes="contact.customAttributes"
          :availability-status="contact.availabilityStatus"
          :is-expanded="expandedCardId === contact.id"
          :is-updating="isUpdating"
          :selectable="shouldShowSelection(contact.id)"
          :is-selected="isSelected(contact.id)"
          @toggle="toggleExpanded(contact.id)"
          @update-contact="updateContact"
          @show-contact="onClickViewDetails"
          @select="value => handleSelect(contact.id, value)"
          @avatar-hover="value => handleAvatarHover(contact.id, value)"
        />
      </div>
    </div>
  </div>
</template>
