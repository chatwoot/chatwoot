<template>
  <div class="datetime-range-picker-container flex gap-1.5">
    <div class="date-picker">
      <date-picker
        :range="false"
        :confirm="true"
        :clearable="false"
        :editable="false"
        :confirm-text="confirmText"
        :placeholder="placeholder"
        :value="selectedDate"
        @change="handleDateChange"
      />
    </div>
    <div class="time-inputs-wrapper flex gap-1.5">
      <div class="flex-1">
        <input
          v-model="startTime"
          type="time"
          class="w-full px-2 py-2 border border-slate-300 dark:border-slate-600 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-800 dark:text-slate-100 max-w-[123px]"
          @change="handleTimeChange"
        />
      </div>
      <div class="flex-1">
        <input
          v-model="endTime"
          type="time"
          class="w-full px-2 py-2 border border-slate-300 dark:border-slate-600 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-800 dark:text-slate-100 max-w-[123px]"
          @change="handleTimeChange"
        />
      </div>
    </div>
  </div>
</template>

<script>
import DatePicker from 'vue2-datepicker';
import { format } from 'date-fns';

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
  data() {
    return {
      selectedDate: new Date(),
      startTime: '00:00',
      endTime: '23:59',
    };
  },
  watch: {
    value: {
      immediate: true,
      handler(newValue) {
        if (newValue && newValue.length === 2) {
          this.selectedDate = new Date(newValue[0]);
          this.startTime = format(new Date(newValue[0]), 'HH:mm');
          this.endTime = format(new Date(newValue[1]), 'HH:mm');
        }
      },
    },
  },
  methods: {
    handleDateChange(value) {
      this.selectedDate = value;
      this.emitChange();
    },
    handleTimeChange() {
      this.emitChange();
    },
    emitChange() {
      if (!this.selectedDate) return;

      // Parse time and set it on the same date
      const [startHour, startMinute] = this.startTime.split(':').map(Number);
      const [endHour, endMinute] = this.endTime.split(':').map(Number);

      const startDateTime = new Date(this.selectedDate);
      startDateTime.setHours(startHour, startMinute, 0, 0);

      const endDateTime = new Date(this.selectedDate);
      endDateTime.setHours(endHour, endMinute, 59, 999);

      this.$emit('change', [startDateTime, endDateTime]);
    },
  },
};
</script>

<style scoped>
.datetime-range-picker-container .date-picker .mx-datepicker-range {
  max-width: 250px !important;
}
</style>
