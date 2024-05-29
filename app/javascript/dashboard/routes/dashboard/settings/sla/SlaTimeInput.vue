<template>
  <div class="flex items-center w-full gap-3">
    <woot-input
      v-model="thresholdTime"
      :class="{ error: $v.thresholdTime.$error }"
      class="flex-grow"
      :styles="{
        borderRadius: '12px',
        padding: '6px 12px',
        fontSize: '14px',
      }"
      :label="label"
      :placeholder="placeholder"
      :error="getThresholdTimeErrorMessage"
      @input="onThresholdTimeChange"
    />
    <!-- the mt-7 handles the label offset -->
    <div class="mt-7">
      <select
        v-model="thresholdUnitValue"
        class="px-4 py-1.5 min-w-[6.5rem] h-10 text-sm font-medium border-0 bg-slate-50 rounded-xl hover:cursor-pointer pr-7 text-slate-800 dark:text-slate-300"
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

<script>
import validationMixin from './validationMixin';
import validations from './validations';

export default {
  mixins: [validationMixin],
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
      this.$v.thresholdTime.$touch();
      const isInvalid = this.$v.thresholdTime.$invalid;
      this.$emit('isInValid', isInvalid);
      this.$emit('input', Number(this.thresholdTime));
    },
  },
};
</script>
