<script setup>
import { ref } from 'vue';
import TagMultiSelectComboBox from './TagMultiSelectComboBox.vue';

const options = [
  { value: 1, label: 'Option 1' },
  { value: 2, label: 'Option 2' },
  { value: 3, label: 'Option 3' },
  { value: 4, label: 'Option 4' },
  { value: 5, label: 'Option 5' },
];
const selectedValues = ref([]);

const preselectedValues = ref([1, 2]);
</script>

<template>
  <Story
    title="Components/TagMultiSelectComboBox"
    :layout="{ type: 'grid', width: '300px' }"
  >
    <Variant title="Default">
      <div class="w-full p-4 bg-white h-80 dark:bg-slate-900">
        <TagMultiSelectComboBox v-model="selectedValues" :options="options" />
        <p class="mt-2">Selected values: {{ selectedValues }}</p>
      </div>
    </Variant>

    <Variant title="With Preselected Values">
      <div class="w-full p-4 bg-white h-80 dark:bg-slate-900">
        <TagMultiSelectComboBox
          v-model="preselectedValues"
          :options="options"
          placeholder="Select multiple options"
        />
      </div>
    </Variant>

    <Variant title="Disabled">
      <div class="w-full p-4 bg-white h-80 dark:bg-slate-900">
        <TagMultiSelectComboBox :options="options" disabled />
      </div>
    </Variant>

    <Variant title="With Error">
      <div class="w-full p-4 bg-white h-80 dark:bg-slate-900">
        <TagMultiSelectComboBox
          :options="options"
          has-error
          message="This field is required"
        />
      </div>
    </Variant>
  </Story>
</template>
