<script setup>
import { computed, ref } from 'vue';
import { useElementBounding, useWindowSize } from '@vueuse/core';
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
  label: {
    type: String,
    default: null,
  },
});

const selected = defineModel({
  type: [String, Number],
  required: true,
});

const triggerRef = ref(null);
const dropdownRef = ref(null);

const { top } = useElementBounding(triggerRef);
const { height } = useWindowSize();
const { height: dropdownHeight } = useElementBounding(dropdownRef);

const selectedOption = computed(() => {
  return props.options.find(o => o.value === selected.value) || {};
});

const iconToRender = computed(() => {
  if (props.hideIcon) return null;
  return selectedOption.value.icon || 'i-lucide-chevron-down';
});

const dropdownPosition = computed(() => {
  const DROPDOWN_MAX_HEIGHT = 340;
  // Get actual height if available or use default
  const menuHeight = dropdownHeight.value
    ? dropdownHeight.value + 20
    : DROPDOWN_MAX_HEIGHT;
  const spaceBelow = height.value - top.value;
  return spaceBelow < menuHeight ? 'bottom-0' : 'top-0';
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
          ref="triggerRef"
          sm
          slate
          :variant
          :icon="iconToRender"
          :trailing-icon="selectedOption.icon ? false : true"
          :label="label || (hideLabel ? null : selectedOption.label)"
          @click="toggle"
        />
      </slot>
    </template>
    <DropdownBody
      ref="dropdownRef"
      class="min-w-48 z-50"
      :class="dropdownPosition"
      strong
    >
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
