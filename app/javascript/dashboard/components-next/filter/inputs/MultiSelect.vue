<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { picoSearch } from '@chatwoot/pico-search';
import { DROPDOWN_SEARCH_THRESHOLD } from '../helper/filterHelper';
import Icon from 'next/icon/Icon.vue';
import EmojiIcon from 'next/emoji-icon-picker/EmojiIcon.vue';
import Button from 'next/button/Button.vue';
import DropdownContainer from 'next/dropdown-menu/base/DropdownContainer.vue';
import DropdownSection from 'next/dropdown-menu/base/DropdownSection.vue';
import DropdownBody from 'next/dropdown-menu/base/DropdownBody.vue';
import DropdownItem from 'next/dropdown-menu/base/DropdownItem.vue';

const { options, maxChips, dropdownMaxHeight } = defineProps({
  options: {
    type: Array,
    required: true,
  },
  maxChips: {
    type: Number,
    default: 3,
  },
  dropdownMaxHeight: {
    type: String,
    default: 'max-h-80',
  },
});

const vFocus = { mounted: el => el.focus() };

const { t } = useI18n();
const selected = defineModel({
  type: [Array, String],
  required: true,
});

const searchTerm = ref('');

const showSearch = computed(() => options.length > DROPDOWN_SEARCH_THRESHOLD);

const searchResults = computed(() => {
  // picoSearch throws on a whitespace-only query, which trims down to no search terms.
  const query = searchTerm.value.trim();
  if (!query) return options;
  return picoSearch(options, query, ['name']);
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

const toggleDropdown = toggle => {
  searchTerm.value = '';
  toggle();
};

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
  <DropdownContainer class="min-w-0">
    <template #trigger="{ toggle }">
      <button
        v-if="hasItems"
        class="bg-n-alpha-2 py-2 rounded-lg h-8 flex items-center px-0 max-w-full"
        @click="toggleDropdown(toggle)"
      >
        <div
          v-for="item in selectedVisibleItems"
          :key="item.name"
          class="px-3 border-e border-n-weak text-n-slate-12 text-sm flex gap-2 items-center max-w-[100px] min-w-0"
        >
          <Icon v-if="item.icon" :icon="item.icon" class="flex-shrink-0" />
          <EmojiIcon
            v-if="item.emoji"
            :value="item.emoji"
            :color="item.iconColor"
            class="flex-shrink-0 size-4"
          />
          <span
            v-if="item.color"
            class="flex-shrink-0 rounded-full size-1.5"
            :style="{ backgroundColor: item.color }"
          />
          <span class="truncate">{{ item.name }}</span>
        </div>
        <div
          v-if="remainingItems.length > 0"
          v-tooltip.top="remainingTooltip"
          class="px-3 border-e border-n-weak text-n-slate-12 text-sm flex gap-2 items-center max-w-[100px] flex-shrink-0"
        >
          <span class="truncate">{{
            t('COMBOBOX.MORE', { count: remainingItems.length })
          }}</span>
        </div>
        <div class="flex items-center border-none px-3 gap-2 flex-shrink-0">
          <Icon icon="i-lucide-plus" />
        </div>
      </button>
      <Button v-else sm slate faded @click="toggleDropdown(toggle)">
        <template #icon>
          <Icon icon="i-lucide-plus" class="text-n-slate-11" />
        </template>
        <span class="text-n-slate-11 min-w-0 truncate">{{
          t('COMBOBOX.PLACEHOLDER')
        }}</span>
      </Button>
    </template>
    <DropdownBody class="top-0 min-w-48 z-50" strong>
      <div v-if="showSearch" class="relative">
        <Icon class="absolute size-4 start-2 top-2" icon="i-lucide-search" />
        <input
          v-model="searchTerm"
          v-focus
          class="p-1.5 ps-8 text-n-slate-11 bg-n-alpha-1 rounded-lg w-full"
          :placeholder="t('COMBOBOX.SEARCH_PLACEHOLDER')"
        />
      </div>
      <DropdownSection :height="dropdownMaxHeight">
        <template v-if="searchResults.length">
          <DropdownItem
            v-for="option in searchResults"
            :key="option.id"
            :icon="option.icon"
            preserve-open
            @click="toggleOption(option)"
          >
            <template v-if="option.emoji || option.color" #icon>
              <EmojiIcon
                v-if="option.emoji"
                :value="option.emoji"
                :color="option.iconColor"
                class="flex-shrink-0 size-4"
              />
              <span
                v-else
                class="flex-shrink-0 rounded-full size-1.5"
                :style="{ backgroundColor: option.color }"
              />
            </template>
            <template #label>
              {{ option.name }}
              <Icon
                v-if="selectedIds.includes(option.id)"
                icon="i-lucide-check"
                class="bg-n-blue-text pointer-events-none"
              />
            </template>
          </DropdownItem>
        </template>
        <template v-else-if="searchTerm">
          <DropdownItem disabled>
            {{ t('COMBOBOX.EMPTY_SEARCH_RESULTS', { searchTerm }) }}
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
