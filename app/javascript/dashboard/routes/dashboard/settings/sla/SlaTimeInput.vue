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
      type: String,
      default: '',
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
  methods: {
    onThresholdUnitChange(event) {
      this.thresholdUnit = event.target.value;
    },
    onThresholdTimeChange(event) {
      this.thresholdTime = event.target.value;
      this.$emit('input', this.thresholdTime);
    },
  },
};
</script>
