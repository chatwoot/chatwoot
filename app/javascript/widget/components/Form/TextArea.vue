<template>
  <label class="block">
    <div
      v-if="label"
      class="mb-2 text-xs leading-3 font-medium"
      :class="labelClass"
    >
      {{ label }}
    </div>
    <textarea
      class="resize-none border rounded w-full py-2 px-3 text-slate-700 leading-tight outline-none"
      :class="isTextAreaHasError"
      :placeholder="placeholder"
      :value="value"
      @change="onChange"
    />
    <div v-if="error" class="text-red-400 mt-2 text-xs leading-3 font-medium">
      {{ error }}
    </div>
  </label>
</template>
<script>
import darkModeMixin from 'widget/mixins/darkModeMixin';
export default {
  mixins: [darkModeMixin],
  props: {
    label: {
      type: String,
      default: '',
    },
    type: {
      type: String,
      default: 'text',
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
<style lang="scss" scoped>
textarea {
  min-height: 8rem;
}
</style>
