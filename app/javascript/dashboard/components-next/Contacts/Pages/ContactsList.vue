<script setup>
import { ref, computed } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import ContactsCard from 'dashboard/components-next/Contacts/ContactsCard/ContactsCard.vue';

const props = defineProps({
  contacts: { type: Array, required: true },
  selectedContactIds: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['toggleContact']);

const router = useRouter();
const route = useRoute();

const hoveredAvatarId = ref(null);

const selectedIdsSet = computed(() => new Set(props.selectedContactIds || []));

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
  <div class="divide-y divide-n-weak">
    <ContactsCard
      v-for="contact in contacts"
      :id="contact.id"
      :key="contact.id"
      :name="contact.name"
      :email="contact.email"
      :thumbnail="contact.thumbnail"
      :phone-number="contact.phoneNumber"
      :additional-attributes="contact.additionalAttributes"
      :availability-status="contact.availabilityStatus"
      :last-activity-at="contact.lastActivityAt"
      :selectable="shouldShowSelection(contact.id)"
      :is-selected="isSelected(contact.id)"
      @show-contact="onClickViewDetails"
      @select="value => handleSelect(contact.id, value)"
      @avatar-hover="value => handleAvatarHover(contact.id, value)"
    />
  </div>
</template>
