<script>
import addDays from 'date-fns/addDays';
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
      type: Date,
      default: [],
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
    disableBeforeToday(date) {
      const yesterdayDate = addDays(new Date(), -1);
      return date < yesterdayDate;
    },
  },
};
</script>

<template>
  <div class="date-picker">
    <DatePicker
      type="datetime"
      :lang="pickerLang"
      confirm
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
