<script>
import DatePicker from 'vue-datepicker-next';
import { currentDatePickerLang } from 'dashboard/helper/datePickerLocale';
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
  computed: {
    pickerLang() {
      return currentDatePickerLang();
    },
  },
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
      :lang="pickerLang"
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
