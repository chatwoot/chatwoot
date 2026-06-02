<script setup>
import { computed, onBeforeUnmount, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { picoSearch } from '@scmmishra/pico-search';
import { debounce } from '@chatwoot/utils';
import Icon from 'next/icon/Icon.vue';
import Button from 'next/button/Button.vue';
import DropdownContainer from 'next/dropdown-menu/base/DropdownContainer.vue';
import DropdownSection from 'next/dropdown-menu/base/DropdownSection.vue';
import DropdownBody from 'next/dropdown-menu/base/DropdownBody.vue';
import DropdownItem from 'next/dropdown-menu/base/DropdownItem.vue';

const {
  options,
  disableSearch,
  disableDeselect,
  placeholderIcon,
  placeholder,
  placeholderTrailingIcon,
  searchPlaceholder,
  searchOptions,
  dropdownMaxHeight,
} = defineProps({
  options: {
    type: Array,
    default: () => [],
  },
  searchOptions: {
    type: Function,
    default: null,
  },
  disableSearch: {
    type: Boolean,
    default: false,
  },
  placeholderIcon: {
    type: String,
    default: 'i-lucide-plus',
  },
  placeholder: {
    type: String,
    default: '',
  },
  placeholderTrailingIcon: {
    type: Boolean,
    default: false,
  },
  searchPlaceholder: {
    type: String,
    default: '',
  },
  dropdownMaxHeight: {
    type: String,
    default: 'max-h-80',
  },
  disableDeselect: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();
const selected = defineModel({
  type: Object,
  required: true,
});

const searchTerm = ref('');
const asyncOptions = ref([]);
const isSearching = ref(false);
let controller = null;

const isAsyncSearch = computed(() => !!searchOptions);

const hasOptionId = option =>
  option && Object.prototype.hasOwnProperty.call(option, 'id');

const selectedValue = computed(() =>
  Array.isArray(selected.value) ? selected.value[0] : selected.value
);

const mergeSelectedOption = results => {
  if (!hasOptionId(selectedValue.value)) return results;
  return [
    selectedValue.value,
    ...results.filter(option => option.id !== selectedValue.value.id),
  ];
};

const isAbortError = error =>
  error?.name === 'AbortError' || error?.name === 'CanceledError';

const performAsyncSearch = async query => {
  controller?.abort();
  const trimmedQuery = query.trim();

  if (!trimmedQuery) {
    asyncOptions.value = hasOptionId(selectedValue.value)
      ? [selectedValue.value]
      : [];
    isSearching.value = false;
    return;
  }

  const currentController = new AbortController();
  controller = currentController;
  isSearching.value = true;

  try {
    const results = await searchOptions(trimmedQuery, {
      signal: currentController.signal,
    });

    if (currentController.signal.aborted) return;
    asyncOptions.value = mergeSelectedOption(results);
  } catch (error) {
    if (!isAbortError(error)) {
      asyncOptions.value = hasOptionId(selectedValue.value)
        ? [selectedValue.value]
        : [];
    }
  } finally {
    if (!currentController.signal.aborted) isSearching.value = false;
  }
};

const debouncedAsyncSearch = debounce(performAsyncSearch, 300);

const searchResults = computed(() => {
  if (isAsyncSearch.value) return asyncOptions.value;
  return picoSearch(options, searchTerm.value, ['name']);
});

const selectedItem = computed(() => {
  const optionToSearch = selectedValue.value;
  if (!hasOptionId(optionToSearch)) return null;

  const optionList = isAsyncSearch.value ? asyncOptions.value : options;
  // extract the selected item from the options array
  // this ensures that options like icon is also included
  return (
    optionList.find(option => option.id === optionToSearch.id) ||
    (isAsyncSearch.value ? optionToSearch : null)
  );
});

const toggleSelected = option => {
  // Ensure that the `icon` prop is not included, icon is a VNode which has circular references
  // This causes an error when creating a clone using JSON.parse(JSON.stringify())
  const optionToToggle = {
    id: option.id,
    name: option.name,
  };

  if (selected.value && selected.value.id === optionToToggle.id) {
    if (!disableDeselect) selected.value = null;
  } else {
    selected.value = optionToToggle;
  }
};

watch(searchTerm, value => {
  if (isAsyncSearch.value) debouncedAsyncSearch(value);
});

watch(
  selectedValue,
  value => {
    if (
      isAsyncSearch.value &&
      hasOptionId(value) &&
      !asyncOptions.value.find(option => option.id === value.id)
    ) {
      asyncOptions.value = [value, ...asyncOptions.value];
    }
  },
  { immediate: true }
);

onBeforeUnmount(() => {
  controller?.abort();
});
</script>

<template>
  <DropdownContainer>
    <template #trigger="{ toggle }">
      <Button
        v-if="selectedItem"
        sm
        slate
        faded
        type="button"
        :icon="selectedItem.icon"
        :label="selectedItem.name"
        @click="toggle"
      />
      <Button
        v-else
        sm
        slate
        faded
        type="button"
        :trailing-icon="placeholderTrailingIcon"
        @click="toggle"
      >
        <template #icon>
          <Icon :icon="placeholderIcon" class="text-n-slate-11" />
        </template>
        <span class="text-n-slate-11">{{
          placeholder || t('COMBOBOX.PLACEHOLDER')
        }}</span>
      </Button>
    </template>
    <DropdownBody class="top-0 min-w-56 z-50" strong>
      <div v-if="!disableSearch" class="relative">
        <Icon class="absolute size-4 left-2 top-2" icon="i-lucide-search" />
        <input
          v-model="searchTerm"
          autofocus
          class="p-1.5 pl-8 text-n-slate-11 bg-n-alpha-1 rounded-lg w-full"
          :placeholder="searchPlaceholder || t('COMBOBOX.SEARCH_PLACEHOLDER')"
        />
      </div>
      <DropdownSection :height="dropdownMaxHeight">
        <template v-if="isSearching">
          <DropdownItem disabled>
            {{ t('DROPDOWN_MENU.SEARCHING') }}
          </DropdownItem>
        </template>
        <template v-else-if="searchResults.length">
          <DropdownItem
            v-for="option in searchResults"
            :key="option.id"
            :icon="option.icon"
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
