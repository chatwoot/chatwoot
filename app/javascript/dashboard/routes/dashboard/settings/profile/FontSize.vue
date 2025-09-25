<script setup>
import { computed } from 'vue';
import FormSelect from 'v3/components/Form/Select.vue';
import { useFontSize } from 'dashboard/composables/useFontSize';

const props = defineProps({
  value: {
    type: String,
    default: 'default',
  },
  label: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['change']);

const { fontSizeOptions } = useFontSize();

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
      name="fontSize"
      spacing="compact"
      class="min-w-28 mt-px"
      :value="selectedValue"
      :options="fontSizeOptions"
      label=""
    >
      <option
        v-for="option in fontSizeOptions"
        :key="option.value"
        :value="option.value"
        :selected="option.value === selectedValue"
      >
        {{ option.label }}
      </option>
    </FormSelect>
  </div>
</template>
