<template>
  <div class="date-picker">
    <date-picker
      :type="type"
      :range="showRange"
      :confirm="true"
      :clearable="false"
      :editable="false"
      :confirm-text="confirmText"
      :placeholder="placeholder"
      :value="value"
      :disabled-date="disableBeforeToday"
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
      type: [Date, Array],
      default: () => [],
    },
    type: {
      type: String,
      default: 'date',
    },
    showRange: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    isTypeDateRange() {
      return this.type !== 'datetime';
    },
  },
  methods: {
    handleChange(value) {
      this.$emit('change', value);
    },
    disableBeforeToday(date) {
      const today = new Date();
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);
      return date < yesterday;
    },
  },
};
</script>

<style lang="scss">
.mx-datepicker-popup {
  z-index: 99999;
}
.date-picker {
  .mx-datepicker {
    width: 100%;
  }
  .mx-datepicker-range {
    width: 320px;
  }
  .mx-input {
    display: flex;
    border: 1px solid var(--color-border);
    border-radius: var(--border-radius-normal);
    box-shadow: none;
    height: 4.6rem;
  }

  .mx-input:disabled,
  .mx-input[readonly] {
    background-color: var(--white);
    cursor: pointer;
  }
}
</style>
