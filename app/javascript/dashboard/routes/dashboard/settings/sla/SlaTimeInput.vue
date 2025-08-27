<script>
import validations from './validations';
import { useVuelidate } from '@vuelidate/core';

export default {
  props: {
    threshold: {
      type: Number,
      default: null,
    },
    thresholdUnit: {
      type: String,
      default: 'Minutes',
    },
    label: {
      type: String,
      default: '',
    },
    placeholder: {
      type: String,
      default: '',
    },
  },
  emits: ['unit', 'isInValid', 'updateThreshold'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      thresholdTime: this.threshold || '',
      thresholdUnitValue: this.thresholdUnit,
      options: [
        { value: 'Minutes', label: 'minutes' },
        { value: 'Hours', label: 'hours' },
        { value: 'Days', label: 'days' },
      ],
    };
  },
  validations,
  computed: {
    thresholdTimeErrorMessage() {
      let errorMessage = '';
      if (this.v$.thresholdTime.$error) {
        if (!this.v$.thresholdTime.numeric || !this.v$.thresholdTime.minValue) {
          errorMessage = this.$t(
            'SLA.FORM.THRESHOLD_TIME.INVALID_FORMAT_ERROR'
          );
        }
      }
      return errorMessage;
    },
  },
  watch: {
    threshold: {
      immediate: true,
      handler(value) {
        if (!Number.isNaN(value)) {
          this.thresholdTime = value;
        }
      },
    },
    thresholdUnit: {
      immediate: true,
      handler(value) {
        this.thresholdUnitValue = value;
      },
    },
  },
  methods: {
    onThresholdUnitChange() {
      this.$emit('unit', this.thresholdUnitValue);
    },
    onThresholdTimeChange() {
      this.v$.thresholdTime.$touch();
      const isInvalid = this.v$.thresholdTime.$invalid;
      this.$emit('isInValid', isInvalid);
      this.$emit(
        'updateThreshold',
        this.thresholdTime ? Number(this.thresholdTime) : null
      );
    },
  },
};
</script>

<template>
  <div class="flex items-center w-full gap-3">
    <woot-input
      v-model="thresholdTime"
      type="number"
      :class="{ error: v$.thresholdTime.$error }"
      class="flex-grow"
      :styles="{
        borderRadius: '0.75rem',
        padding: '0.375rem 0.75rem',
        fontSize: '0.875rem',
      }"
      :label="label"
      :placeholder="placeholder"
      :error="thresholdTimeErrorMessage"
      @update:model-value="onThresholdTimeChange"
    />
    <!-- the mt-7 handles the label offset -->
    <div class="mt-7">
      <select
        v-model="thresholdUnitValue"
        class="px-4 py-1.5 min-w-[6.5rem] h-10 text-sm font-medium border-0 rounded-xl hover:cursor-pointer pr-7"
        @change="onThresholdUnitChange"
      >
        <option
          v-for="(option, index) in options"
          :key="index"
          :value="option.value"
        >
          {{ option.label }}
        </option>
      </select>
    </div>
  </div>
</template>
