<template>
  <div class="date-picker">
    <date-picker
      :type="showTime ? 'datetime' : 'date'"
      :range="true"
      :confirm="true"
      :clearable="false"
      :editable="false"
      :confirm-text="confirmText"
      :placeholder="placeholder"
      :value="value"
      :format="showTime ? 'YYYY-MM-DD HH:mm' : 'YYYY-MM-DD'"
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
    showTime: {
      type: Boolean,
      default: false,
    },
  },
  methods: {
    handleChange(value) {
      this.$emit('change', value);
    },
  },
};
</script>
