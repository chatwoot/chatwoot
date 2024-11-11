<script setup>
import { computed, defineModel } from 'vue';
import Button from 'next/button/Button.vue';
import FilterSelect from './FilterSelect.vue';
import { useConversationFilterContext } from './provider.js';

const props = defineProps({
  values: { type: [String, Number, Array], required: true },
  isFirst: { type: Boolean, default: false },
  // attributeModel: { type: String, required: true },
  // customAttributeType: { type: String, default: '' },
});

const emit = defineEmits(['remove']);
const { filterTypes } = useConversationFilterContext();

const attributeKey = defineModel('attributeKey', {
  type: String,
  required: true,
});

const filterOperator = defineModel('filterOperator', {
  type: String,
  required: true,
});

const queryOperator = defineModel('queryOperator', {
  type: String,
  required: true,
  validator: value => ['and', 'or'].includes(value),
});

const toggleQueryOperator = () => {
  queryOperator.value = queryOperator.value === 'and' ? 'or' : 'and';
};

const currentFilter = computed(() => {
  return filterTypes.value.find(filterObj => {
    return filterObj.attribute_key === attributeKey.value;
  });
});

const valueToShow = computed(() => {
  if (Array.isArray(props.values)) {
    return props.values.map(v => v.name).join(', ');
  }

  return props.values;
});
</script>

<template>
  <div class="flex items-center gap-2 rounded-md">
    <Button
      v-if="!isFirst"
      sm
      faded
      slate
      class="text-xs font-mono tracking-wider min-w-12"
      :label="queryOperator === 'and' ? 'AND' : 'OR'"
      @click="toggleQueryOperator"
    />
    <FilterSelect
      v-model="attributeKey"
      variant="faded"
      :options="filterTypes"
    />
    <FilterSelect
      v-model="filterOperator"
      variant="ghost"
      :options="currentFilter.filter_operators"
    />
    <Button v-if="valueToShow" sm faded slate>
      {{ valueToShow }}
    </Button>
    <Button sm solid slate icon="i-lucide-x" @click="emit('remove')" />
  </div>
</template>
