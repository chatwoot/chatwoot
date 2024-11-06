<script setup>
import { computed, watch, onMounted, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';

import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  contactId: {
    type: [String, Number],
    default: null,
  },
});

const store = useStore();
const { t } = useI18n();
const route = useRoute();

const showDropdown = ref(false);

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
      action: 'addLabel',
    }))
    .toSorted((a, b) => Number(a.isSelected) - Number(b.isSelected));
});

const fetchLabels = async contactId => {
  if (!contactId) {
    return;
  }
  store.dispatch('contactLabels/get', contactId);
};

const handleLabelAction = async ({ action, value }) => {
  try {
    // Get current label titles
    const currentLabels = savedLabels.value.map(label => label.title);

    // Find the label title for the ID (value)
    const selectedLabel = allLabels.value.find(label => label.id === value);
    if (!selectedLabel) return;

    let updatedLabels;
    if (action === 'addLabel') {
      // If label is already selected, remove it (toggle behavior)
      if (currentLabels.includes(selectedLabel.title)) {
        updatedLabels = currentLabels.filter(
          labelTitle => labelTitle !== selectedLabel.title
        );
      } else {
        // Add the new label
        updatedLabels = [...currentLabels, selectedLabel.title];
      }
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
</script>

<template>
  <div class="flex flex-wrap items-center gap-2">
    <div
      v-for="label in savedLabels"
      :key="label.id"
      class="bg-n-alpha-2 rounded-md flex items-center h-7 w-fit py-1 ltr:pl-1 rtl:pr-1 ltr:pr-1.5 rtl:pl-1.5"
    >
      <div
        class="w-2 h-2 m-1 rounded-sm"
        :style="{ backgroundColor: label.color }"
      />
      <span class="text-sm text-n-slate-12">
        {{ label.title }}
      </span>
    </div>
    <div class="relative">
      <button
        class="flex items-center gap-1 px-2 py-1 rounded-md outline-dashed h-[26px] outline-1 outline-n-slate-6 hover:bg-n-alpha-2"
        :class="{ 'bg-n-alpha-2': showDropdown }"
        @click="showDropdown = !showDropdown"
      >
        <span class="i-lucide-plus" />
        <span class="text-sm text-n-slate-11">
          {{ t('CONTACTS_LAYOUT.DETAILS.TAG_BUTTON') }}
        </span>
      </button>
      <DropdownMenu
        v-if="showDropdown"
        v-on-clickaway="() => (showDropdown = false)"
        :menu-items="labelMenuItems"
        show-search
        class="z-[100] w-48 mt-2 overflow-y-auto ltr:left-0 rtl:right-0 top-full max-h-52"
        @action="handleLabelAction"
      >
        <template #thumbnail="{ item }">
          <div
            class="rounded-sm size-2"
            :style="{ backgroundColor: item.thumbnail.color }"
          />
        </template>
      </DropdownMenu>
    </div>
  </div>
</template>
