<script setup>
import { defineModel } from 'vue';
import Icon from 'next/icon/Icon.vue';
import DropdownContainer from 'next/dropdown-menu/base/DropdownContainer.vue';
import DropdownBody from 'next/dropdown-menu/base/DropdownBody.vue';
import DropdownItem from 'next/dropdown-menu/base/DropdownItem.vue';

defineProps({
  options: {
    type: Array,
    required: true,
  },
});

const selected = defineModel({
  type: [Array],
  required: true,
});

const toggleOption = optionToToggle => {
  const selectedValues = selected.value.map(value => value.name);
  const valueToToggle = optionToToggle.name;

  if (selectedValues.includes(valueToToggle)) {
    selected.value = selected.value.filter(
      value => value.name !== valueToToggle
    );
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
          v-for="item in selected"
          :key="item.name"
          class="px-3 border-r border-n-weak text-n-slate-12 text-sm"
        >
          {{ item.name }}
        </div>
        <button class="flex items-center border-none px-3" @click="toggle">
          <Icon icon="i-lucide-plus" />
        </button>
      </div>
    </template>
    <DropdownBody class="top-0 min-w-48 z-[999]">
      <DropdownItem
        v-for="option in options"
        :key="option.value"
        :label="option.label"
        :icon="option.icon"
        @click="toggleOption(option)"
      />
    </DropdownBody>
  </DropdownContainer>
</template>
