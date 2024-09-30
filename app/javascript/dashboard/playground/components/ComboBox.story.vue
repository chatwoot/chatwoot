<script setup>
import { ref } from 'vue';
import ComboBox from './ComboBox.vue';

const options = [
  { value: 1, label: 'Option 1' },
  { value: 2, label: 'Option 2' },
  { value: 3, label: 'Option 3' },
  { value: 4, label: 'Option 4' },
  { value: 5, label: 'Option 5' },
];

const selectedValue = ref('');
</script>

<template>
  <Story title="Components/ComboBox" :layout="{ type: 'grid', width: '300px' }">
    <Variant title="Default">
      <div class="w-full h-80">
        <ComboBox :options="options" placeholder="Select an option..." />
      </div>
    </Variant>

    <Variant title="With Preselected Value">
      <div class="w-full h-80">
        <ComboBox :options="options" :model-value="2" />
      </div>
    </Variant>

    <Variant title="Custom Placeholder">
      <div class="w-full h-80">
        <ComboBox :options="options" placeholder="Choose wisely..." />
      </div>
    </Variant>

    <Variant title="With v-model">
      <div class="w-full h-80">
        <ComboBox v-model="selectedValue" :options="options" />
        <p class="mt-2">Selected value: {{ selectedValue }}</p>
      </div>
    </Variant>

    <Variant title="Disabled">
      <div class="w-full h-80">
        <ComboBox :options="options" disabled />
      </div>
    </Variant>
  </Story>
</template>
