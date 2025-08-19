<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { debounce } from '@chatwoot/utils';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, default: '' },
});

const emit = defineEmits(['search']);

const { t } = useI18n();

const searchInputValue = ref(props.searchValue);

const debouncedSearch = debounce(value => {
  emit('search', value);
}, 300);

watch(searchInputValue, newValue => {
  debouncedSearch(newValue);
});

const clearSearch = () => {
  searchInputValue.value = '';
};
</script>

<template>
  <header class="flex flex-col gap-4 p-6 border-b border-n-weak bg-n-solid-1">
    <div class="flex items-center justify-between">
      <h1 class="text-2xl font-semibold text-n-base">
        {{ headerTitle }}
      </h1>

      <Button color="blue" icon="i-lucide-plus" size="sm">
        {{ t('LIBRARY.HEADER.ADD_RESOURCE') }}
      </Button>
    </div>

    <div class="flex gap-4">
      <div class="flex-1 max-w-md">
        <Input
          v-model="searchInputValue"
          :placeholder="t('LIBRARY.HEADER.SEARCH_PLACEHOLDER')"
        >
          <template v-if="searchInputValue" #suffix>
            <button
              class="p-1 text-n-slate-10 hover:text-n-slate-12"
              @click="clearSearch"
            >
              <span class="i-lucide-x size-4" />
            </button>
          </template>
        </Input>
      </div>
    </div>
  </header>
</template>
