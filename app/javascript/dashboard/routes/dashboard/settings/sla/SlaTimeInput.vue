<template>
  <div class="relative mt-2 w-full">
    <woot-input
      v-model="thresholdTime"
      class="w-full [&>input]:pr-20"
      :label="label"
      :placeholder="placeholder"
      @input="onThresholdTimeChange"
    />
    <div class="absolute right-px h-[2.3rem] top-[26px] flex items-center">
      <label for="response" class="sr-only">SLA</label>
      <select
        id="response"
        name="response"
        class="h-full rounded-[4px] hover:cursor-pointer font-medium border-1 border-solid bg-transparent border-transparent dark:border-transparent mb-0 py-0 pl-2 pr-7 text-slate-600 dark:text-slate-300 dark:focus:border-woot-500 focus:border-woot-500 text-sm"
        @change="onThresholdUnitChange"
      >
        <option>Minutes</option>
        <option>Hours</option>
        <option>Days</option>
      </select>
    </div>
  </div>
</template>
<script>
export default {
  props: {
    threshold: {
      type: Number,
      default: null,
    },
    label: {
      type: String,
      default: '',
    },
    placeholder: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      thresholdTime: this.threshold || '',
      thresholdUnit: 'Minutes',
    };
  },
  computed: {
    thresholdInSeconds() {
      if (this.thresholdUnit === 'Minutes') {
        return this.thresholdTime * 60;
      }
      if (this.thresholdUnit === 'Hours') {
        return this.thresholdTime * 3600;
      }
      if (this.thresholdUnit === 'Days') {
        return this.thresholdTime * 86400;
      }
      return this.thresholdTime;
    },
    // write a method to convert from seconds to the selected unit
    // the response from api will always be in seconds
    // convert it to minutes if seconds is less than 3600
    // convert it to hours if seconds is less than 86400
    // convert it to days if seconds is greater than 86400

    thresholdInUnit() {
      if (this.thresholdInSeconds < 3600) {
        return `${this.thresholdInSeconds / 60} Minutes`;
      }
      if (this.thresholdInSeconds < 86400) {
        return `${this.thresholdInSeconds / 3600} Hours`;
      }
      return `${this.thresholdInSeconds / 86400} Days`;
    },
  },
  watch: {
    threshold(newVal) {
      this.thresholdTime = newVal;
    },
  },
  methods: {
    onThresholdUnitChange(event) {
      this.thresholdUnit = event.target.value;
      // Convert the threshold time to seconds
      //   this.thresholdTime = this.thresholdInSeconds;
    },
    onThresholdTimeChange(event) {
      this.thresholdTime = Number(event);
      this.$emit('input', this.thresholdTime);
    },
  },
};
</script>
