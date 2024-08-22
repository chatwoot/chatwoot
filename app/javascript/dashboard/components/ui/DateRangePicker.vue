<template>
  <div class="date-picker">
    <date-picker
      :range="true"
      :confirm="true"
      :clearable="false"
      :editable="false"
      :confirm-text="confirmText"
      :placeholder="placeholder"
      :value="value"
      :disabled-date="dateLimiter"
      @change="handleChange"
    />
  </div>
</template>

<script>
import DatePicker from 'vue2-datepicker';
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
    limitTime: {
      type: Number,
      default: 0,
    },
  },
  computed: {
    dateLimiter() {
      return this.limitTime > 0
        ? this.disabledBeforeTodayAndAfterAWeek
        : () => false;
    },
  },
  methods: {
    handleChange(value) {
      this.$emit('change', value);
    },
    disabledBeforeTodayAndAfterAWeek(date) {
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      return (
        date > today ||
        date < new Date(today.getTime() - this.limitTime * 24 * 3600 * 1000)
      );
    },
  },
};
</script>
