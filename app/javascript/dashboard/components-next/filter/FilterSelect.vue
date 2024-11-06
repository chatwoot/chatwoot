<script setup>
import { computed } from 'vue';
import DropdownContainer from 'next/dropdown-menu/base/DropdownContainer.vue';
import DropdownBody from 'next/dropdown-menu/base/DropdownBody.vue';
import DropdownItem from 'next/dropdown-menu/base/DropdownItem.vue';

import Button from 'next/button/Button.vue';

// [{label, icon, value}]
const props = defineProps({
  options: {
    type: Array,
    required: true,
  },
});

const selected = defineModel({
  type: Object,
  required: true,
});

const selectedOption = computed(() =>
  props.options.find(o => o.value === selected.value)
);
</script>

<template>
  <DropdownContainer>
    <template #trigger="{ toggle }">
      <Button sm ghost slate :icon="selectedOption.icon" @click="toggle">
        {{ selectedOption.label }}
      </Button>
    </template>
    <DropdownBody class="top-0 w-64 z-[909999]">
      <DropdownItem
        v-for="option in options"
        :key="option.value"
        :label="option.label"
        :icon="option.icon"
        @click="() => (selected = option.value)"
      />
    </DropdownBody>
  </DropdownContainer>
</template>
