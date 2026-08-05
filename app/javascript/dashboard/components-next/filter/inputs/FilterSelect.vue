<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useElementBounding, useWindowSize } from '@vueuse/core';
import DropdownContainer from 'next/dropdown-menu/base/DropdownContainer.vue';
import DropdownSection from 'next/dropdown-menu/base/DropdownSection.vue';
import DropdownBody from 'next/dropdown-menu/base/DropdownBody.vue';
import DropdownItem from 'next/dropdown-menu/base/DropdownItem.vue';

import Button from 'next/button/Button.vue';
import Icon from 'next/icon/Icon.vue';

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
  searchable: {
    type: Boolean,
    default: false,
  },
});

const selected = defineModel({
  type: [String, Number],
  required: true,
});

const vFocus = { mounted: el => el.focus() };

const { t } = useI18n();

const searchQuery = ref('');
const triggerRef = ref(null);
const dropdownRef = ref(null);

const filteredOptions = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();
  if (!props.searchable || !query) return props.options;
  return props.options.filter(
    option =>
      !option.disabled && (option.label || '').toLowerCase().includes(query)
  );
});

const { top } = useElementBounding(triggerRef);
const { height } = useWindowSize();
const { height: dropdownHeight } = useElementBounding(dropdownRef);

const selectedOption = computed(() => {
  return props.options?.find(o => o.value === selected.value) || {};
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
  searchQuery.value = '';
};

const handleTriggerClick = toggle => {
  searchQuery.value = '';
  toggle();
};
</script>

<template>
  <DropdownContainer>
    <template #trigger="{ toggle }">
      <slot name="trigger" :toggle="toggle">
        <Button
          ref="triggerRef"
          type="button"
          sm
          slate
          :variant
          :icon="iconToRender"
          :trailing-icon="selectedOption.icon ? false : true"
          :label="label || (hideLabel ? null : selectedOption.label)"
          @click="handleTriggerClick(toggle)"
        />
      </slot>
    </template>
    <DropdownBody
      ref="dropdownRef"
      class="min-w-56 z-50"
      :class="dropdownPosition"
      strong
    >
      <div v-if="searchable" class="relative">
        <Icon class="absolute size-4 left-2 top-2" icon="i-lucide-search" />
        <input
          v-model="searchQuery"
          v-focus
          class="w-full p-1.5 pl-8 rounded-lg text-n-slate-11 bg-n-alpha-1"
          :placeholder="t('FILTER.SEARCH_PLACEHOLDER')"
        />
      </div>
      <DropdownSection class="[&>ul]:max-h-72">
        <template v-for="option in filteredOptions" :key="option.value">
          <li
            v-if="option.disabled"
            class="px-2 py-1.5 text-xs font-medium text-n-slate-10 select-none"
          >
            {{ option.label }}
          </li>
          <DropdownItem
            v-else
            :label="option.label"
            :icon="option.icon"
            @click="updateSelected(option.value)"
          />
        </template>
        <li
          v-if="searchable && !filteredOptions.length"
          class="px-2 py-1.5 text-sm text-n-slate-10 select-none"
        >
          {{ t('FILTER.NO_RESULTS') }}
        </li>
      </DropdownSection>
    </DropdownBody>
  </DropdownContainer>
</template>
