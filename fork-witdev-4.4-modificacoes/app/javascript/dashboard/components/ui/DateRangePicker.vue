<script>
import DatePicker from 'vue-datepicker-next';
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
  emits: ['change'],
  methods: {
    handleChange(value) {
      this.$emit('change', value);
    },
  },
};
</script>

<template>
  <div class="date-picker">
    <DatePicker
      range
      confirm
      :clearable="false"
      :editable="false"
      :confirm-text="confirmText"
      :placeholder="placeholder"
      :value="value"
      @change="handleChange"
    />
  </div>
</template>
