<template>
  <div class="date-picker">
    <date-picker
      type="datetime"
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
import addDays from 'date-fns/addDays';
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
      type: Date,
      default: [],
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
