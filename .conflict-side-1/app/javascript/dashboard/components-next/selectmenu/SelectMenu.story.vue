<script setup>
import { ref } from 'vue';
import SelectMenu from './SelectMenu.vue';

const sampleOptions = [
  { label: 'Option 1', value: 'option1' },
  { label: 'Option 2', value: 'option2' },
  { label: 'Option 3', value: 'option3' },
  { label: 'Option 4', value: 'option4' },
];

const selectedValue = ref('option1');
</script>

<template>
  <Story
    title="Components/SelectMenu"
    :layout="{ type: 'grid', width: '400px' }"
  >
    <Variant title="Default">
      <div class="flex flex-col gap-4 p-4 h-[400px]">
        <SelectMenu
          v-model="selectedValue"
          :options="sampleOptions"
          :label="sampleOptions.find(opt => opt.value === selectedValue)?.label"
        />
        <div class="text-sm">Selected value: {{ selectedValue }}</div>
      </div>
    </Variant>

    <Variant title="With Many Options">
      <div class="flex flex-col gap-4 p-4 h-[400px]">
        <SelectMenu
          v-model="selectedValue"
          :options="
            Array.from({ length: 10 }, (_, i) => ({
              label: `Option ${i + 1}`,
              value: `value${i + 1}`,
            }))
          "
          label="Select from many"
        />
      </div>
    </Variant>
  </Story>
</template>
