<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useElementBounding, useWindowSize } from '@vueuse/core';
import { picoSearch } from '@chatwoot/pico-search';
import { DROPDOWN_SEARCH_THRESHOLD } from '../helper/filterHelper';
import DropdownContainer from 'next/dropdown-menu/base/DropdownContainer.vue';
import DropdownSection from 'next/dropdown-menu/base/DropdownSection.vue';
import DropdownBody from 'next/dropdown-menu/base/DropdownBody.vue';
import DropdownItem from 'next/dropdown-menu/base/DropdownItem.vue';

import Button from 'next/button/Button.vue';
import Icon from 'next/icon/Icon.vue';

// [{label, icon, value}]
const props = defineProps({
  // Empty while an attribute the saved filter refers to no longer exists.
  options: {
    type: Array,
    default: () => [],
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

const { t } = useI18n();
const selected = defineModel({
  type: [String, Number],
  required: true,
});

const vFocus = { mounted: el => el.focus() };

const triggerRef = ref(null);
const dropdownRef = ref(null);
const searchTerm = ref('');

const showSearch = computed(
  () => props.options.length > DROPDOWN_SEARCH_THRESHOLD
);

const searchResults = computed(() => {
  // picoSearch throws on a whitespace-only query, which trims down to no search terms.
  const query = searchTerm.value.trim();
  if (!query) return props.options;
  // Section headers are not selectable, so they are dropped once a query narrows the list.
  const selectableOptions = props.options.filter(option => !option.disabled);
  return picoSearch(selectableOptions, query, ['label']);
});

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

const toggleDropdown = toggle => {
  searchTerm.value = '';
  toggle();
};
</script>

<template>
  <DropdownContainer>
    <template #trigger="{ toggle }">
      <slot name="trigger" :toggle="() => toggleDropdown(toggle)">
        <Button
          ref="triggerRef"
          type="button"
          sm
          slate
          :variant
          :icon="iconToRender"
          :trailing-icon="selectedOption.icon ? false : true"
          :label="label || (hideLabel ? null : selectedOption.label)"
          @click="toggleDropdown(toggle)"
        />
      </slot>
    </template>
    <DropdownBody
      ref="dropdownRef"
      class="min-w-56 z-50"
      :class="dropdownPosition"
      strong
    >
      <div v-if="showSearch" class="relative">
        <Icon class="absolute size-4 left-2 top-2" icon="i-lucide-search" />
        <input
          v-model="searchTerm"
          v-focus
          class="w-full p-1.5 pl-8 rounded-lg text-n-slate-11 bg-n-alpha-1"
          :placeholder="t('COMBOBOX.SEARCH_PLACEHOLDER')"
        />
      </div>
      <DropdownSection class="[&>ul]:max-h-72">
        <template v-for="option in searchResults" :key="option.value">
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
        <DropdownItem v-if="!searchResults.length" disabled>
          {{
            searchTerm
              ? t('COMBOBOX.EMPTY_SEARCH_RESULTS', { searchTerm })
              : t('COMBOBOX.EMPTY_STATE')
          }}
        </DropdownItem>
      </DropdownSection>
    </DropdownBody>
  </DropdownContainer>
</template>
