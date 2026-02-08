<script setup>
import { ref } from 'vue';
import FilterSelect from './FilterSelect.vue';

const options = [
  { value: 'EQUAL_TO', label: 'Equal To', icon: 'i-ph-equals-bold' },
  {
    value: 'NOT_EQUAL_TO',
    label: 'Not Equal To',
    icon: 'i-ph-not-equals-bold',
  },
  { value: 'IS_PRESENT', label: 'Is Present', icon: 'i-ph-member-of-bold' },
  {
    value: 'IS_NOT_PRESENT',
    label: 'Is Not Present',
    icon: 'i-ph-not-member-of-bold',
  },
  { value: 'CONTAINS', label: 'Contains', icon: 'i-ph-superset-of-bold' },
  {
    value: 'DOES_NOT_CONTAIN',
    label: 'Does Not Contain',
    icon: 'i-ph-not-superset-of-bold',
  },
  {
    value: 'IS_GREATER_THAN',
    label: 'Is Greater Than',
    icon: 'i-ph-greater-than-bold',
  },
  { value: 'IS_LESS_THAN', label: 'Is Less Than', icon: 'i-ph-less-than-bold' },
  {
    value: 'DAYS_BEFORE',
    label: 'Days Before',
    icon: 'i-ph-calendar-minus-bold',
  },
  {
    value: 'STARTS_WITH',
    label: 'Starts With',
    icon: 'i-ph-caret-line-right-bold',
  },
];

const selected = ref(options[0].value);
</script>

<template>
  <Story
    title="Components/Filters/Filter Select"
    :layout="{ type: 'grid', width: '250px' }"
  >
    <Variant title="With Icon & Label">
      <div class="min-h-[400px]">
        <FilterSelect v-model="selected" :options="options" />
      </div>
    </Variant>
    <Variant title="Without Icon">
      <div class="min-h-[400px]">
        <FilterSelect v-model="selected" hide-icon :options="options" />
      </div>
    </Variant>
    <Variant title="Without Label">
      <div class="min-h-[400px]">
        <FilterSelect v-model="selected" hide-label :options="options" />
      </div>
    </Variant>
  </Story>
</template>
