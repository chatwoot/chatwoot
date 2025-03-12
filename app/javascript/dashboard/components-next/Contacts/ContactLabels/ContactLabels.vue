<script setup>
import { computed, watch, onMounted, ref } from 'vue';
import { useRoute } from 'vue-router';
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
const route = useRoute();

const showDropdown = ref(false);

// Store the currently hovered label's ID
// Using JS state management instead of CSS :hover / group hover
// This will solve the flickering issue when hovering over the last label item
const hoveredLabel = ref(null);

const allLabels = useMapGetter('labels/getLabels');
const contactLabels = useMapGetter('contactLabels/getContactLabels');

const savedLabels = computed(() => {
  const availableContactLabels = contactLabels.value(props.contactId);
  return allLabels.value.filter(({ title }) =>
    availableContactLabels.includes(title)
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

const fetchLabels = async contactId => {
  if (!contactId) {
    return;
  }
  store.dispatch('contactLabels/get', contactId);
};

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

    showDropdown.value = false;
  } catch (error) {
    // error
  }
};

const handleRemoveLabel = labelId => {
  return handleLabelAction({ value: labelId });
};

watch(
  () => props.contactId,
  (newVal, oldVal) => {
    if (newVal !== oldVal) {
      fetchLabels(newVal);
    }
  }
);
onMounted(() => {
  if (route.params.contactId) {
    fetchLabels(route.params.contactId);
  }
});

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
  <div class="flex flex-wrap items-center gap-2" @mouseleave="handleMouseLeave">
    <LabelItem
      v-for="label in savedLabels"
      :key="label.id"
      :label="label"
      :is-hovered="hoveredLabel === label.id"
      @remove="handleRemoveLabel"
      @hover="handleLabelHover(label.id)"
    />
    <AddLabel
      :label-menu-items="labelMenuItems"
      @update-label="handleLabelAction"
    />
  </div>
</template>
