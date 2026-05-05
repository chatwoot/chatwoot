<script setup>
import Input from 'dashboard/components-next/input/Input.vue';
import PhoneNumberInput from 'dashboard/components-next/phonenumberinput/PhoneNumberInput.vue';

const props = defineProps({
  modelValue: {
    type: Array,
    default: () => [],
  },
  type: {
    type: String,
    required: true,
    validator: value => ['email', 'phone'].includes(value),
  },
  primaryValue: {
    type: String,
    default: '',
  },
  label: {
    type: String,
    required: true,
  },
  addLabel: {
    type: String,
    required: true,
  },
  promoteLabel: {
    type: String,
    required: true,
  },
  removeLabel: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['update:modelValue', 'promote']);

const updateRows = rows => emit('update:modelValue', rows);

const addRow = () => {
  updateRows([...props.modelValue, '']);
};

const updateRow = (index, value) => {
  updateRows(
    props.modelValue.map((row, rowIndex) => (rowIndex === index ? value : row))
  );
};

const removeRow = index => {
  updateRows(props.modelValue.filter((_, rowIndex) => rowIndex !== index));
};

const promoteRow = value => {
  emit('promote', value);
};
</script>

<template>
  <div class="flex flex-col gap-3">
    <div class="flex items-center justify-between gap-3">
      <span class="py-1 text-sm font-medium text-n-slate-12">
        {{ label }}
      </span>
      <button
        type="button"
        data-testid="contact-point-add"
        class="inline-flex items-center justify-center rounded-lg p-2 text-n-brand hover:bg-n-alpha-2"
        :aria-label="addLabel"
        :title="addLabel"
        @click="addRow"
      >
        <span class="i-lucide-plus size-4" />
      </button>
    </div>

    <div class="flex flex-col gap-3">
      <div
        v-for="(value, index) in modelValue"
        :key="index"
        class="flex items-center gap-2"
      >
        <Input
          v-if="type === 'email'"
          :model-value="value"
          type="email"
          data-testid="contact-point-input"
          class="min-w-0 flex-1"
          custom-input-class="h-8 !pt-1 !pb-1"
          @update:model-value="updateRow(index, $event)"
        />
        <PhoneNumberInput
          v-else
          :model-value="value"
          data-testid="contact-point-input"
          class="min-w-0 flex-1"
          @update:model-value="updateRow(index, $event)"
        />
        <button
          type="button"
          data-testid="contact-point-promote"
          class="inline-flex size-8 flex-shrink-0 items-center justify-center rounded-lg text-n-slate-11 hover:bg-n-alpha-2 disabled:cursor-not-allowed disabled:opacity-50"
          :aria-label="promoteLabel"
          :title="promoteLabel"
          :disabled="value === primaryValue"
          @click="promoteRow(value)"
        >
          <span class="i-lucide-arrow-up size-4" />
        </button>
        <button
          type="button"
          data-testid="contact-point-remove"
          class="inline-flex size-8 flex-shrink-0 items-center justify-center rounded-lg text-n-ruby-9 hover:bg-n-ruby-3"
          :aria-label="removeLabel"
          :title="removeLabel"
          @click="removeRow(index)"
        >
          <span class="i-lucide-trash-2 size-4" />
        </button>
      </div>
    </div>
  </div>
</template>
