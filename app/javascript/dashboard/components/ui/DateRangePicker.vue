<template>
  <div class="woot-date-range-picker">
    <date-picker
      :range="true"
      :confirm="true"
      :clearable="false"
      :confirm-text="confirmText"
      :placeholder="placeholder"
      :value="value"
      @change="handleChange"
    />
  </div>
</template>

<script>
import DatePicker from 'vue2-datepicker';
import 'vue2-datepicker/index.css';
export default {
  components: { DatePicker },
  props: {
    confirmText: {
      type: String,
      default: '',
    },
    placeholder: {
      type: String,
      default: '',
    },
    value: {
      type: Array,
      default: () => [],
    },
  },
  methods: {
    updateValue(val) {
      this.$emit('change', val);
    },
    handleChange(value) {
      this.updateValue(value);
    },
  },
};
</script>

<style lang="scss">
.woot-date-range-picker {
  margin-left: var(--space-smaller);

  .mx-input {
    display: flex;
    border: 1px solid var(--color-border);
    border-radius: var(--border-radius-normal);
    box-shadow: none;
    height: 4.6rem;
  }
}
</style>
