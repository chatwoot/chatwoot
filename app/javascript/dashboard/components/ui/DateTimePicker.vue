<script>
import addDays from 'date-fns/addDays';
import DatePicker from 'vue-datepicker-next';
export default {
  components: { DatePicker },
  props: {
    confirmText: {
      type: String,
      default: 'Confirmar',
    },
    placeholder: {
      type: String,
      default: 'Selecione data e hora',
    },
    value: {
      type: Date,
      default: null,
    },
  },
  emits: ['change'],

  data() {
    return {
      lang: {
        days: ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'],
        months: ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'],
        yearFormat: 'YYYY',
        monthFormat: 'MMMM',
      },
    };
  },

  computed: {
    internalValue: {
      get() {
        return this.value;
      },
      set(newValue) {
        this.$emit('change', newValue);
      },
    },
  },

  methods: {
    handleConfirm(value) {
      this.$emit('change', value);
    },
    disableBeforeToday(date) {
      const yesterdayDate = addDays(new Date(), -1);
      return date < yesterdayDate;
    },
    disabledTime(date) {
      // Allow only time after 1 hour from now
      const now = new Date();
      now.setHours(now.getHours() + 1);
      return date < now;
    },
  },
};
</script>

<template>
  <div class="date-picker">
    <DatePicker
      v-model:value="internalValue"
      type="datetime"
      inline
      confirm
      :clearable="false"
      :editable="false"
      :confirm-text="confirmText"
      :placeholder="placeholder"
      :disabled-date="disableBeforeToday"
      :disabled-time="disabledTime"
      :lang="lang"
      input-class="mx-input"
      @confirm="handleConfirm"
    />
  </div>
</template>
