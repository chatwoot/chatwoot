<script setup>
import { defineModel, computed } from 'vue';
import Icon from 'next/icon/Icon.vue';
import DropdownContainer from 'next/dropdown-menu/base/DropdownContainer.vue';
import DropdownBody from 'next/dropdown-menu/base/DropdownBody.vue';
import DropdownItem from 'next/dropdown-menu/base/DropdownItem.vue';

const { options } = defineProps({
  options: {
    type: Array,
    required: true,
  },
});

const selected = defineModel({
  type: [Array],
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

const toggleOption = optionToToggle => {
  if (!hasItems.value) {
    selected.value = [optionToToggle];
    return;
  }

  const idToToggle = optionToToggle.id;
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
      <div class="bg-n-alpha-2 py-2 rounded-lg h-8 flex items-center">
        <div
          v-for="item in selectedItems"
          :key="item.name"
          class="px-3 border-r border-n-weak text-n-slate-12 text-sm flex gap-2 items-center"
        >
          <Icon v-if="item.icon" :icon="item.icon" class="flex-shrink-0" />
          <span>{{ item.name }}</span>
        </div>
        <button class="flex items-center border-none px-3" @click="toggle">
          <Icon icon="i-lucide-plus" />
        </button>
      </div>
    </template>
    <DropdownBody class="top-0 min-w-48 z-[999]">
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
    </DropdownBody>
  </DropdownContainer>
</template>
