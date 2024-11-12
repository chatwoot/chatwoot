<script setup>
import { defineModel, computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { picoSearch } from '@scmmishra/pico-search';
import Icon from 'next/icon/Icon.vue';
import Button from 'next/button/Button.vue';
import DropdownContainer from 'next/dropdown-menu/base/DropdownContainer.vue';
import DropdownSection from 'next/dropdown-menu/base/DropdownSection.vue';
import DropdownBody from 'next/dropdown-menu/base/DropdownBody.vue';
import DropdownItem from 'next/dropdown-menu/base/DropdownItem.vue';

const { options } = defineProps({
  options: {
    type: Array,
    required: true,
  },
});

const { t } = useI18n();
const selected = defineModel({
  type: Object,
  required: true,
});

const searchTerm = ref('');
const searchResults = computed(() => {
  if (!options) return [];
  return picoSearch(options, searchTerm.value, ['name']);
});

const selectedItem = computed(() => {
  if (!options) return null;
  // extract the selected item from the options array
  // this ensures that options like icon is also included
  return options.find(option => option.id === selected.value.id);
});

const toggleSelected = newValue => {
  if (selected.value.id === newValue.id) {
    selected.value = {};
  } else {
    selected.value = newValue;
  }
};
</script>

<template>
  <DropdownContainer>
    <template #trigger="{ toggle }">
      <Button
        v-if="selectedItem"
        sm
        slate
        faded
        :icon="selectedItem.icon"
        :label="selectedItem.name"
        @click="toggle"
      />
      <Button
        v-else
        sm
        slate
        faded
        icon="i-lucide-plus"
        label="Select"
        @click="toggle"
      />
    </template>
    <DropdownBody class="top-0 min-w-56 z-[999]">
      <div class="relative">
        <Icon class="absolute size-4 left-2 top-2" icon="i-lucide-search" />
        <input
          v-model="searchTerm"
          autofocus
          class="p-1.5 pl-8 text-n-slate-11 bg-n-alpha-1 rounded-lg"
          :placeholder="t('COMBOBOX.SEARCH_PLACEHOLDER')"
        />
      </div>
      <DropdownSection class="max-h-80 overflow-scroll">
        <template v-if="searchResults.length">
          <DropdownItem
            v-for="option in searchResults"
            :key="option.id"
            :icon="option.icon"
            preserve-open
            @click="toggleSelected(option)"
          >
            <template #label>
              {{ option.name }}
              <Icon
                v-if="selectedItem && selectedItem.id === option.id"
                icon="i-lucide-check"
                class="bg-n-blue-text pointer-events-none"
              />
            </template>
          </DropdownItem>
        </template>
        <template v-else-if="searchTerm">
          <DropdownItem disabled>
            {{ t('COMBOBOX.EMPTY_SEARCH_RESULTS', { searchTerm: searchTerm }) }}
          </DropdownItem>
        </template>
        <template v-else>
          <DropdownItem disabled>
            {{ t('COMBOBOX.EMPTY_STATE') }}
          </DropdownItem>
        </template>
      </DropdownSection>
    </DropdownBody>
  </DropdownContainer>
</template>
