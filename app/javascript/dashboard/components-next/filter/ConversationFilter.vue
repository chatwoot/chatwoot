<script setup>
import Button from 'next/button/Button.vue';
import ConditionRow from './ConditionRow.vue';
import { defineModel } from 'vue';

const filters = defineModel({
  type: Array,
  default: [],
});
</script>

<template>
  <div class="bg-n-alpha-3 border border-n-weak p-6 rounded-xl">
    <div class="mt-1 mb-3 font-medium text-base tracking-tight leading-6">
      {{ 'Filters' }}
    </div>
    <ConditionRow v-for="filter in filters" :key="filter.id" v-bind="filter" />

    <div class="flex gap-2 justify-between">
      <Button sm ghost blue> Cancel </Button>
      <div class="flex gap-2">
        <Button sm faded slate> Clear all </Button>
        <Button sm solid blue> Apply filter </Button>
      </div>
    </div>
  </div>
</template>
