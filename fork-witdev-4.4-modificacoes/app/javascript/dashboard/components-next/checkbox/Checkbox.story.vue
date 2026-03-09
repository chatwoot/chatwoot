<script setup>
import Checkbox from './Checkbox.vue';
import { ref } from 'vue';

const defaultValue = ref(false);
const isChecked = ref(false);
const checkedValue = ref(true);
const indeterminateValue = ref(true);
</script>

<template>
  <Story title="Components/Checkbox" :layout="{ type: 'grid', width: '250px' }">
    <Variant title="States">
      <div class="p-2 space-y-4">
        <div class="flex items-center justify-between gap-4">
          <span>Default:</span>
          <Checkbox v-model="defaultValue" />
        </div>

        <div class="flex items-center justify-between gap-4">
          <span>Checked:</span>
          <Checkbox v-model="checkedValue" />
        </div>

        <div class="flex items-center justify-between gap-4">
          <span>Indeterminate:</span>
          <Checkbox v-model="indeterminateValue" indeterminate />
        </div>

        <div class="flex items-center justify-between gap-4">
          <span>Indeterminate disabled:</span>
          <Checkbox v-model="indeterminateValue" indeterminate disabled />
        </div>

        <div class="flex items-center justify-between gap-4">
          <span>Disabled:</span>
          <Checkbox v-model="defaultValue" disabled />
        </div>

        <div class="flex items-center justify-between gap-4">
          <span>Disabled Checked:</span>
          <Checkbox v-model="isChecked" disabled />
        </div>
      </div>
    </Variant>
  </Story>
</template>
