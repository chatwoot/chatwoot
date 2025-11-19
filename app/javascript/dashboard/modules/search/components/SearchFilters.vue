<script setup>
import { ref } from 'vue';
import SearchDateRangeSelector from './SearchDateRangeSelector.vue';
import SearchEntitySelector from './SearchEntitySelector.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['update:filters']);

const filters = ref({
  from: null,
  to: null,
  dateRange: { from: null, to: null },
});

const onDateRangeChange = ({ from, to }) => {
  filters.value.dateRange = { from, to };
  emit('update:filters', filters.value);
};

const onEntityChange = (key, value) => {
  filters.value[key] = value;
  emit('update:filters', filters.value);
};
</script>

<template>
  <div class="flex items-center gap-2 p-4 w-full">
    <SearchDateRangeSelector
      v-model:from="filters.dateRange.from"
      v-model:to="filters.dateRange.to"
      @change="onDateRangeChange"
    />

    <div class="w-px h-4 bg-n-weak mx-1" />

    <SearchEntitySelector
      :model-value="filters.from"
      :label="$t('SEARCH.FILTERS.FROM')"
      @update:model-value="val => onEntityChange('from', val)"
    />

    <SearchEntitySelector
      :model-value="filters.to"
      :label="$t('SEARCH.FILTERS.TO')"
      @update:model-value="val => onEntityChange('to', val)"
    />

    <Button
      sm
      outline
      slate
      label="Mention"
      trailing-icon
      icon="i-lucide-chevron-down"
      class="outline-dashed"
    />
  </div>
</template>
