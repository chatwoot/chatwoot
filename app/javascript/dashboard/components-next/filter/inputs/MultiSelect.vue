<script setup>
import { defineModel, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'next/icon/Icon.vue';
import Button from 'next/button/Button.vue';
import DropdownContainer from 'next/dropdown-menu/base/DropdownContainer.vue';
import DropdownSection from 'next/dropdown-menu/base/DropdownSection.vue';
import DropdownBody from 'next/dropdown-menu/base/DropdownBody.vue';
import DropdownItem from 'next/dropdown-menu/base/DropdownItem.vue';

const { options, maxChips } = defineProps({
  options: {
    type: Array,
    required: true,
  },
  maxChips: {
    type: Number,
    default: 3,
  },
});

const { t } = useI18n();
const selected = defineModel({
  type: [Array, String],
  required: true,
});

const hasItems = computed(() => {
  if (!selected.value) return false;
  if (!Array.isArray(selected.value)) return false;
  if (selected.value.length === 0) return false;

  return true;
});

const selectedIds = computed(() => {
  if (!hasItems.value) return [];
  return selected.value.map(value => value.id);
});

const selectedItems = computed(() => {
  // Options has additional properties, so we need to use them directly
  if (!hasItems.value) return [];
  return options.filter(option => selectedIds.value.includes(option.id));
});

const selectedVisibleItems = computed(() => {
  if (!hasItems.value) return [];
  // avoid showing "+1 more" coz it takes up space anway, might as well show it
  if (selectedItems.value.length === maxChips + 1) return selectedItems.value;
  // if we have more than maxChips then show only maxChips
  return selectedItems.value.slice(0, maxChips);
});

const remainingItems = computed(() => {
  if (!hasItems.value) return [];
  if (selectedItems.value.length === maxChips + 1) return [];
  return selectedItems.value.slice(maxChips);
});

const remainingTooltip = computed(() => {
  if (!hasItems.value) return '';
  return remainingItems.value.map(item => item.name).join(', ');
});

const toggleOption = option => {
  // Ensure that the `icon` prop is not included, icon is a VNode which has circular references
  // This causes an error when creating a clone using JSON.parse(JSON.stringify())
  const optionToToggle = {
    id: option.id,
    name: option.name,
  };

  const idToToggle = optionToToggle.id;

  if (!hasItems.value) {
    selected.value = [optionToToggle];
    return;
  }

  if (selectedIds.value.includes(idToToggle)) {
    selected.value = selected.value.filter(value => value.id !== idToToggle);
  } else {
    selected.value = [...selected.value, optionToToggle];
  }
};
</script>

<template>
  <DropdownContainer>
    <template #trigger="{ toggle }">
      <button
        v-if="hasItems"
        class="bg-n-alpha-2 py-2 rounded-lg h-8 flex items-center px-0"
        @click="toggle"
      >
        <div
          v-for="item in selectedVisibleItems"
          :key="item.name"
          class="px-3 border-r rtl:border-l rtl:border-r-0 border-n-weak text-n-slate-12 text-sm flex gap-2 items-center max-w-[100px]"
        >
          <Icon v-if="item.icon" :icon="item.icon" class="flex-shrink-0" />
          <span class="truncate">{{ item.name }}</span>
        </div>
        <div
          v-if="remainingItems.length > 0"
          v-tooltip.top="remainingTooltip"
          class="px-3 border-r rtl:border-l rtl:border-r-0 border-n-weak text-n-slate-12 text-sm flex gap-2 items-center max-w-[100px]"
        >
          <span class="truncate">{{
            t('COMBOBOX.MORE', { count: remainingItems.length })
          }}</span>
        </div>
        <div class="flex items-center border-none px-3 gap-2">
          <Icon icon="i-lucide-plus" />
        </div>
      </button>
      <Button v-else sm slate faded @click="toggle">
        <template #icon>
          <Icon icon="i-lucide-plus" class="text-n-slate-11" />
        </template>
        <span class="text-n-slate-11">{{ t('COMBOBOX.PLACEHOLDER') }}</span>
      </Button>
    </template>
    <DropdownBody class="top-0 min-w-48 z-50" strong>
      <DropdownSection class="max-h-80 overflow-scroll">
        <DropdownItem
          v-for="option in options"
          :key="option.id"
          :icon="option.icon"
          preserve-open
          @click="toggleOption(option)"
        >
          <template #label>
            {{ option.name }}
            <Icon
              v-if="selectedIds.includes(option.id)"
              icon="i-lucide-check"
              class="bg-n-blue-text pointer-events-none"
            />
          </template>
        </DropdownItem>
      </DropdownSection>
    </DropdownBody>
  </DropdownContainer>
</template>
