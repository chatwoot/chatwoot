<template>
  <div class="relative mt-2 w-full">
    <woot-input
      v-model="thresholdTime"
      :class="{ error: $v.thresholdTime.$error }"
      class="w-full [&>input]:pr-24"
      :label="label"
      :placeholder="placeholder"
      :error="getThresholdTimeErrorMessage"
      @input="onThresholdTimeChange"
    />
    <div class="absolute right-px h-9 top-[27px] flex items-center">
      <select
        v-model="thresholdUnitValue"
        class="h-full rounded-[4px] hover:cursor-pointer font-medium border-1 border-solid bg-transparent border-transparent dark:border-transparent mb-0 py-0 pl-2 pr-7 text-slate-600 dark:text-slate-300 dark:focus:border-woot-500 focus:border-woot-500 text-sm"
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
        { value: 'Minutes', label: 'Minutes' },
        { value: 'Hours', label: 'Hours' },
        { value: 'Days', label: 'Days' },
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
