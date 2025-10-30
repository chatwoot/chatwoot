<script setup>
import { ref } from 'vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import AppointmentsSortMenu from './components/AppointmentsSortMenu.vue';
import AppointmentsFilter from 'dashboard/components-next/filter/AppointmentsFilter.vue';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';

defineProps({
  showSearch: { type: Boolean, default: true },
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, required: true },
  activeSort: { type: String, default: 'start_time' },
  activeOrdering: { type: String, default: '-' },
  hasActiveFilters: { type: Boolean, default: false },
});

const emit = defineEmits([
  'search',
  'update:sort',
  'applyFilter',
  'clearFilters',
]);

const showFiltersModal = ref(false);
const appliedFilter = ref([]);

const onToggleFilters = () => {
  showFiltersModal.value = !showFiltersModal.value;
};

const closeAdvanceFiltersModal = () => {
  showFiltersModal.value = false;
};

const onApplyFilter = async payload => {
  appliedFilter.value = JSON.parse(JSON.stringify(payload));
  emit('applyFilter', useSnakeCase(JSON.parse(JSON.stringify(payload))));
  showFiltersModal.value = false;
};

const clearFilters = async () => {
  appliedFilter.value = [];
  emit('clearFilters');
};
</script>

<template>
  <header class="sticky top-0 z-10">
    <div
      class="flex items-start sm:items-center justify-between w-full py-6 px-6 gap-2 mx-auto max-w-[60rem]"
    >
      <span class="text-xl font-medium truncate text-n-slate-12">
        {{ headerTitle }}
      </span>
      <div class="flex items-center flex-col sm:flex-row flex-shrink-0 gap-4">
        <div v-if="showSearch" class="flex items-center gap-2 w-full">
          <Input
            :model-value="searchValue"
            type="search"
            :placeholder="$t('CONTACTS_LAYOUT.HEADER.SEARCH_PLACEHOLDER')"
            :custom-input-class="[
              'h-8 [&:not(.focus)]:!border-transparent bg-n-alpha-2 dark:bg-n-solid-1 ltr:!pl-8 !py-1 rtl:!pr-8',
            ]"
            class="w-full"
            @input="emit('search', $event.target.value)"
          >
            <template #prefix>
              <Icon
                icon="i-lucide-search"
                class="absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-2 rtl:right-2"
              />
            </template>
          </Input>
        </div>
        <div class="flex items-center flex-shrink-0 gap-2">
          <div class="relative">
            <Button
              id="toggleAppointmentsFilterButton"
              icon="i-lucide-list-filter"
              color="slate"
              size="sm"
              class="relative w-8"
              variant="ghost"
              @click="onToggleFilters"
            >
              <div
                v-if="hasActiveFilters"
                class="absolute top-0 right-0 w-2 h-2 rounded-full bg-n-brand"
              />
            </Button>
            <div
              class="absolute mt-1 ltr:-right-52 rtl:-left-52 sm:ltr:right-0 sm:rtl:left-0 top-full"
            >
              <AppointmentsFilter
                v-if="showFiltersModal"
                v-model="appliedFilter"
                @apply-filter="onApplyFilter"
                @close="closeAdvanceFiltersModal"
                @clear-filters="clearFilters"
              />
            </div>
          </div>
          <AppointmentsSortMenu
            :active-sort="activeSort"
            :active-ordering="activeOrdering"
            @update:sort="emit('update:sort', $event)"
          />
        </div>
      </div>
    </div>
  </header>
</template>
