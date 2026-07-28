<script setup>
import { computed } from 'vue';
import BaseInput from 'widget-v2/components/base/BaseInput.vue';

const props = defineProps({
  fields: { type: Array, required: true },
  errors: { type: Object, default: () => ({}) },
});

const values = defineModel({ type: Object, required: true });

// Standard fields map onto contact columns; everything else is a custom
// attribute keyed by its name.
const INPUT_TYPES = {
  email: 'email',
  text: 'text',
  number: 'number',
  date: 'date',
};

const enabledFields = computed(() =>
  props.fields.filter(field => field.enabled)
);

const isList = field => field.type === 'list';
const isCheckbox = field => field.type === 'checkbox';
</script>

<template>
  <div class="flex flex-col gap-4">
    <template v-for="field in enabledFields" :key="field.name">
      <label v-if="isCheckbox(field)" class="flex items-center gap-2.5">
        <input
          v-model="values[field.name]"
          type="checkbox"
          class="w-4 h-4 rounded-[4px] accent-cw-primary"
        />
        <span class="text-sm text-cw-text">
          {{ field.label }}
          <span v-if="field.required" class="text-n-ruby-11">*</span>
        </span>
      </label>

      <label v-else-if="isList(field)" class="block">
        <span class="block mb-1.5 text-xs font-medium text-cw-text-muted">
          {{ field.label }}
          <span v-if="field.required" class="text-n-ruby-11">*</span>
        </span>
        <select
          v-model="values[field.name]"
          class="w-full h-10 px-3 text-base rounded-token-sm bg-cw-solid text-cw-text border border-cw-border outline-none transition-shadow focus-visible:ring-[3px] focus-visible:ring-cw-ring"
          :class="{ 'border-n-ruby-8': errors[field.name] }"
        >
          <option value="">{{ field.placeholder || field.label }}</option>
          <option v-for="value in field.values" :key="value" :value="value">
            {{ value }}
          </option>
        </select>
        <span
          v-if="errors[field.name]"
          class="block mt-1 text-xs text-n-ruby-11"
        >
          {{ errors[field.name] }}
        </span>
      </label>

      <BaseInput
        v-else
        v-model="values[field.name]"
        :type="INPUT_TYPES[field.type] || 'text'"
        :label="`${field.label}${field.required ? ' *' : ''}`"
        :placeholder="field.placeholder"
        :error="errors[field.name]"
      />
    </template>
  </div>
</template>
