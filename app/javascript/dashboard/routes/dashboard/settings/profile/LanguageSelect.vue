<script setup>
import { computed } from 'vue';
import FormSelect from 'v3/components/Form/Select.vue';

const props = defineProps({
  value: { type: String, default: '' }, // empty = use account default
  options: { type: Array, required: true },
  label: { type: String, default: '' },
  description: { type: String, default: '' },
});
const emit = defineEmits(['change']);
const selectedValue = computed({
  get: () => props.value,
  set: value => {
    emit('change', value);
  },
});
</script>

<template>
  <div class="flex gap-2 justify-between w-full items-start">
    <div>
      <label class="text-n-gray-12 font-medium leading-6 text-sm">
        {{ label }}
      </label>
      <p class="text-n-gray-11">
        {{ description }}
      </p>
    </div>
    <FormSelect
      v-model="selectedValue"
      name="language"
      spacing="compact"
      class="min-w-28 mt-px"
      :options="options"
      label=""
    >
      <option
        v-for="option in options"
        :key="option.iso_639_1_code || 'default'"
        :value="option.iso_639_1_code"
        :selected="option.iso_639_1_code === selectedValue"
      >
        {{ option.name }}
      </option>
    </FormSelect>
  </div>
</template>
