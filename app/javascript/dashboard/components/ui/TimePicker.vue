<script>
export default {
  props: {
    value: {
      type: String,
      default: '',
    },
    placeholder: {
      type: String,
      default: 'Select time',
    },
    disabled: {
      type: Boolean,
      default: false,
    },
    minTime: {
      type: String,
      default: '',
    },
    maxTime: {
      type: String,
      default: '',
    },
    step: {
      type: Number,
      default: 60, // Step in seconds (60 = 1 minute)
    },
  },
  emits: ['change', 'input'],

  computed: {
    formattedValue() {
      if (!this.value) return '';
      // Ensure value is in HH:MM format
      if (this.value.includes(':')) {
        const [hours, minutes] = this.value.split(':');
        return `${hours.padStart(2, '0')}:${minutes.padStart(2, '0')}`;
      }
      return this.value;
    },
    stepInMinutes() {
      return Math.floor(this.step / 60);
    },
  },

  methods: {
    handleChange(event) {
      const newValue = event.target.value;
      this.$emit('input', newValue);
      this.$emit('change', newValue);
    },
  },
};
</script>

<template>
  <div class="time-picker">
    <input
      type="time"
      :value="formattedValue"
      :placeholder="placeholder"
      :disabled="disabled"
      :min="minTime"
      :max="maxTime"
      :step="step"
      class="time-input"
      @input="handleChange"
      @change="handleChange"
    />
  </div>
</template>

<style scoped>
.time-picker {
  display: inline-block;
  width: 100%;
}

.time-input {
  width: 100%;
  padding: var(--space-small);
  border: 1px solid var(--color-border);
  border-radius: var(--border-radius-normal);
  font-size: var(--font-size-small);
  line-height: 1.5;
  color: var(--color-body);
  background-color: var(--color-white);
  transition: border-color 0.15s ease-in-out;
}

.time-input:focus {
  outline: 0;
  border-color: var(--w-500);
  box-shadow: 0 0 0 1px var(--w-500);
}

.time-input:disabled {
  cursor: not-allowed;
  background-color: var(--b-50);
  opacity: 0.6;
}

/* Ensure consistency with other date/time pickers */
.time-input::-webkit-calendar-picker-indicator {
  cursor: pointer;
  opacity: 0.6;
}

.time-input::-webkit-calendar-picker-indicator:hover {
  opacity: 1;
}
</style>