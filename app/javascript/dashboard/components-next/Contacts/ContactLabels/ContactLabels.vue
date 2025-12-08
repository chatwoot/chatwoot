<script setup>
import { computed, ref, watch } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';

import LabelItem from 'dashboard/components-next/Label/LabelItem.vue';
import AddLabel from 'dashboard/components-next/Label/AddLabel.vue';

const props = defineProps({
  contactId: {
    type: [String, Number],
    default: null,
  },
});

const store = useStore();

const showDropdown = ref(false);

// Store the currently hovered label's ID
// Using JS state management instead of CSS :hover / group hover
// This will solve the flickering issue when hovering over the last label item
const hoveredLabel = ref(null);

const allLabels = useMapGetter('labels/getLabels');
const getContactById = useMapGetter('contacts/getContactById');
const getContactLabels = useMapGetter('contactLabels/getContactLabels');

const savedLabels = computed(() => {
  const contactLabelsList = getContactLabels.value(props.contactId) || [];

  return allLabels.value.filter(({ title }) =>
    contactLabelsList.includes(title)
  );
});

const labelMenuItems = computed(() => {
  return allLabels.value
    ?.map(label => ({
      label: label.title,
      value: label.id,
      thumbnail: { name: label.title, color: label.color },
      isSelected: savedLabels.value.some(
        savedLabel => savedLabel.id === label.id
      ),
      action: 'contactLabel',
    }))
    .toSorted((a, b) => Number(a.isSelected) - Number(b.isSelected));
});

const handleLabelAction = async ({ value }) => {
  try {
    // Get current label titles
    const currentLabels = savedLabels.value.map(label => label.title);

    // Find the label title for the ID (value)
    const selectedLabel = allLabels.value.find(label => label.id === value);
    if (!selectedLabel) return;

    let updatedLabels;

    // If label is already selected, remove it (toggle behavior)
    if (currentLabels.includes(selectedLabel.title)) {
      updatedLabels = currentLabels.filter(
        labelTitle => labelTitle !== selectedLabel.title
      );
    } else {
      // Add the new label
      updatedLabels = [...currentLabels, selectedLabel.title];
    }

    await store.dispatch('contactLabels/update', {
      contactId: props.contactId,
      labels: updatedLabels,
    });

    store.dispatch('contacts/updateContactLabels', {
      contactId: props.contactId,
      labels: updatedLabels,
    });

    showDropdown.value = false;
  } catch (error) {
    // error
  }
};

const handleRemoveLabel = label => {
  return handleLabelAction({ value: label.id });
};

// Sync contact labels from contact object to contactLabels store when contact loads
watch(
  () => getContactById.value(props.contactId),
  contact => {
    if (contact?.labels) {
      store.dispatch('contactLabels/setContactLabel', {
        id: props.contactId,
        data: contact.labels,
      });
    }
  },
  { immediate: true }
);

const handleMouseLeave = () => {
  // Reset hover state when mouse leaves the container
  // This ensures all labels return to their default state
  hoveredLabel.value = null;
};

const handleLabelHover = labelId => {
  // Added this to prevent flickering on when showing remove button on hover
  // If the label item is at end of the line, it will show the remove button
  // when hovering over the last label item
  hoveredLabel.value = labelId;
};
</script>

<template>
  <div
    class="flex flex-wrap items-center gap-2 ltr:mr-10 rtl:ml-10"
    @mouseleave="handleMouseLeave"
  >
    <LabelItem
      v-for="label in savedLabels"
      :key="label.id"
      :label="label"
      :is-hovered="hoveredLabel === label.id"
      class="ltr:!pr-1 rtl:!pl-1"
      @remove="handleRemoveLabel"
      @hover="handleLabelHover(label.id)"
    />
    <AddLabel
      :label-menu-items="labelMenuItems"
      @update-label="handleLabelAction"
    />
  </div>
</template>
