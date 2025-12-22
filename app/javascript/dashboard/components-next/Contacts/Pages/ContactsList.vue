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

const props = defineProps({
  contacts: { type: Array, required: true },
  selectedContactIds: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['toggleContact']);

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

const handleSelect = (id, value) => {
  emit('toggleContact', { id, value });
};

const handleAvatarHover = (id, isHovered) => {
  hoveredAvatarId.value = isHovered ? id : null;
};
</script>

<template>
  <div class="flex flex-col gap-4">
    <div v-for="contact in contacts" :key="contact.id" class="relative">
      <ContactsCard
        :id="contact.id"
        :name="contact.name"
        :email="contact.email"
        :thumbnail="contact.thumbnail"
        :phone-number="contact.phoneNumber"
        :additional-attributes="contact.additionalAttributes"
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
</template>
