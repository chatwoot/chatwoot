<script>
import parsePhoneNumber from 'libphonenumber-js';

export default {
  props: {
    modelValue: {
      type: [String, Number],
      default: '',
    },
    placeholder: {
      type: String,
      default: '',
    },
    readonly: {
      type: Boolean,
      default: false,
    },
    styles: {
      type: Object,
      default: () => {},
    },
    error: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['blur', 'update:modelValue'],
  data() {
    return {
      phoneNumber: this.modelValue,
    };
  },
  watch: {
    modelValue() {
      this.phoneNumber = this.modelValue;
    },
  },
  methods: {
    onChange(e) {
      this.phoneNumber = e.target.value;
      this.$emit('update:modelValue', this.phoneNumber);
    },
    onBlur(e) {
      this.$emit('blur', e.target.value);
    },
  },
};
</script>

<template>
  <div class="relative phone-input--wrap">
    <div
      class="flex items-center justify-start border border-solid rounded-md dark:bg-slate-900"
      :class="
        error
          ? 'border border-solid border-red-400 dark:border-red-400 mb-1'
          : 'mb-4 border-slate-200 dark:border-slate-600'
      "
    >
      <input
        ref="phoneNumberInput"
        :value="phoneNumber"
        type="tel"
        class="!mb-0 !border-0 font-normal !w-full dark:!bg-slate-900 text-base !px-1.5 placeholder:font-normal"
        :placeholder="placeholder"
        :readonly="readonly"
        :style="styles"
        @input="onChange"
        @blur="onBlur"
      />
    </div>
  </div>
</template>
