<script>
import darkModeMixin from 'widget/mixins/darkModeMixin';
export default {
  mixins: [darkModeMixin],
  props: {
    label: {
      type: String,
      default: '',
    },
    placeholder: {
      type: String,
      default: '',
    },
    value: {
      type: [String, Number],
      required: true,
    },
    error: {
      type: String,
      default: '',
    },
  },
  computed: {
    labelClass() {
      return this.error
        ? `text-red-400 ${this.$dm('text-black-800', 'dark:text-slate-50')}`
        : `text-black-800 ${this.$dm('text-black-800', 'dark:text-slate-50')}`;
    },
    isTextAreaDarkOrLightMode() {
      return `${this.$dm('bg-white', 'dark:bg-slate-600')} ${this.$dm(
        'text-slate-700',
        'dark:text-slate-50'
      )}`;
    },
    textAreaBorderColor() {
      return `${this.$dm('border-black-200', 'dark:border-black-500')}`;
    },
    isTextAreaHasError() {
      return this.error
        ? `border-red-200 hover:border-red-300 focus:border-red-300 ${this.isTextAreaDarkOrLightMode}`
        : `hover:border-black-300 focus:border-black-300 ${this.isTextAreaDarkOrLightMode} ${this.textAreaBorderColor}`;
    },
  },
  methods: {
    onChange(event) {
      this.$emit('input', event.target.value);
    },
  },
};
</script>

<template>
  <label class="block">
    <div
      v-if="label"
      class="mb-2 text-xs font-medium leading-3"
      :class="labelClass"
    >
      {{ label }}
    </div>
    <textarea
      class="w-full px-3 py-2 leading-tight border rounded outline-none resize-none text-slate-700"
      :class="isTextAreaHasError"
      :placeholder="placeholder"
      :value="value"
      @change="onChange"
    />
    <div v-if="error" class="mt-2 text-xs font-medium leading-3 text-red-400">
      {{ error }}
    </div>
  </label>
</template>

<style lang="scss" scoped>
textarea {
  min-height: 8rem;
}
</style>
