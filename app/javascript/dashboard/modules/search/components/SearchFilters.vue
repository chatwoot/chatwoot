<script setup>
import { computed, defineModel } from 'vue';
import { useI18n } from 'vue-i18n';
import SearchDateRangeSelector from './SearchDateRangeSelector.vue';
import SearchContactAgentSelector from './SearchContactAgentSelector.vue';
import SearchInboxSelector from './SearchInboxSelector.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['updateFilters']);
const { t } = useI18n();

const filters = defineModel({
  type: Object,
  default: () => ({
    from: null, // Contact id and Agent id
    in: null, // Inbox id
    dateRange: { type: null, from: null, to: null },
  }),
});

const hasActiveFilters = computed(
  () =>
    filters.value.from ||
    filters.value.in ||
    filters.value.dateRange?.type ||
    filters.value.dateRange?.from ||
    filters.value.dateRange?.to
);

const onFilterChange = () => {
  emit('updateFilters', filters.value);
};

const clearAllFilters = () => {
  filters.value = {
    from: null,
    in: null,
    dateRange: { type: null, from: null, to: null },
  };
  onFilterChange();
};
</script>

<template>
  <div
    class="flex flex-col lg:flex-row items-start lg:items-center gap-3 p-4 w-full min-w-0"
  >
    <div class="flex items-center gap-3 min-w-0 max-w-full">
      <Button
        v-if="hasActiveFilters"
        sm
        slate
        solid
        :label="t('SEARCH.DATE_RANGE.CLEAR_FILTER')"
        icon="i-lucide-x"
        class="flex-shrink-0 lg:hidden"
        @click="clearAllFilters"
      />

      <SearchDateRangeSelector
        v-model="filters.dateRange"
        class="min-w-0 max-w-full"
        @change="onFilterChange"
      />
    </div>

    <div class="w-px h-4 bg-n-weak flex-shrink-0 hidden lg:block" />

    <div class="flex items-center gap-1.5 min-w-0 flex-1 max-w-full">
      <span class="text-sm text-n-slate-10 flex-shrink-0 whitespace-nowrap">
        {{ t('SEARCH.FILTERS.FILTER_MESSAGE') }}
      </span>

      <div class="min-w-0">
        <SearchContactAgentSelector
          v-model="filters.from"
          :label="$t('SEARCH.FILTERS.FROM')"
          @change="onFilterChange"
        />
      </div>

      <div class="w-px h-3 bg-n-weak rounded-lg flex-shrink-0" />

      <div class="min-w-0">
        <SearchInboxSelector
          v-model="filters.in"
          :label="$t('SEARCH.FILTERS.IN')"
          @change="onFilterChange"
        />
      </div>
    </div>

    <Button
      v-if="hasActiveFilters"
      sm
      slate
      solid
      :label="t('SEARCH.DATE_RANGE.CLEAR_FILTER')"
      icon="i-lucide-x"
      class="flex-shrink-0 hidden lg:inline-flex"
      @click="clearAllFilters"
    />
  </div>
</template>
