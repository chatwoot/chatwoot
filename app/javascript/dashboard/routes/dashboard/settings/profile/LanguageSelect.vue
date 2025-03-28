<script setup>
import { computed } from 'vue';
import FormSelect from 'v3/components/Form/Select.vue';
import languages from 'dashboard/components/widgets/conversation/advancedFilterItems/languages'; // Import the languages array

const props = defineProps({
  value: {
    type: String,
    default: 'en', // Default to English
  },
  label: {
    type: String,
    default: 'Language', // Update label to "Language"
  },
  description: {
    type: String,
    default: 'Select your preferred language.', // Update description
  },
});

const emit = defineEmits(['change']);

// Map the languages array to the format expected by FormSelect
const languageOptions = languages.map(language => ({
  value: language.id,
  label: language.name,
}));

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
      :value="selectedValue"
      :options="languageOptions"
      label=""
    >
      <option
        v-for="option in languageOptions"
        :key="option.value"
        :value="option.value"
        :selected="option.value === selectedValue"
      >
        {{ option.label }}
      </option>
    </FormSelect>
  </div>
</template>
