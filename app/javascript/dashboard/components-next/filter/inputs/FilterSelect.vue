<script setup>
import { computed } from 'vue';
import DropdownContainer from 'next/dropdown-menu/base/DropdownContainer.vue';
import DropdownSection from 'next/dropdown-menu/base/DropdownSection.vue';
import DropdownBody from 'next/dropdown-menu/base/DropdownBody.vue';
import DropdownItem from 'next/dropdown-menu/base/DropdownItem.vue';

import Button from 'next/button/Button.vue';

// [{label, icon, value}]
const props = defineProps({
  options: {
    type: Array,
    required: true,
  },
  hideLabel: {
    type: Boolean,
    default: false,
  },
  hideIcon: {
    type: Boolean,
    default: false,
  },
  variant: {
    type: String,
    default: 'faded',
  },
});

const selected = defineModel({
  type: [String, Number],
  required: true,
});

const selectedOption = computed(() => {
  return props.options.find(o => o.value === selected.value) || {};
});

const iconToRender = computed(() => {
  if (props.hideIcon) return null;
  return selectedOption.value.icon || 'i-lucide-chevron-down';
});

const updateSelected = newValue => {
  selected.value = newValue;
};
</script>

<template>
  <DropdownContainer>
    <template #trigger="{ toggle }">
      <slot name="trigger" :toggle="toggle">
        <Button
          sm
          slate
          :variant
          :icon="iconToRender"
          :trailing-icon="selectedOption.icon ? false : true"
          :label="hideLabel ? null : selectedOption.label"
          @click="toggle"
        />
      </slot>
    </template>
    <DropdownBody class="top-0 min-w-48 z-50" strong>
      <DropdownSection class="max-h-80 overflow-scroll">
        <DropdownItem
          v-for="option in options"
          :key="option.value"
          :label="option.label"
          :icon="option.icon"
          @click="updateSelected(option.value)"
        />
      </DropdownSection>
    </DropdownBody>
  </DropdownContainer>
</template>
