<template>
  <with-label
    :label="label"
    :name="name"
    :has-error="hasError"
    :error-message="errorMessage"
  >
    <textarea
      :id="name"
      :name="name"
      autocomplete="off"
      :required="required"
      :placeholder="placeholder"
      :data-testid="dataTestid"
      :value="value"
      :rows="rows"
      :class="{
        'focus:outline-red-600 outline-red-600': hasError,
        'dark:outline-slate-600 dark:focus:outline-woot-500 outline-slate-200 focus:outline-woot-500':
          !hasError,
        'resize-none': !allowResize,
      }"
      class="block w-full p-3 bg-white border-none rounded-md shadow-sm appearance-none outline outline-1 focus:outline focus:outline-2 text-slate-900 dark:text-slate-100 placeholder:text-slate-400 dark:bg-slate-800"
      @input="onInput"
      @blur="$emit('blur')"
    />
  </with-label>
</template>
<script>
import WithLabel from './WithLabel.vue';
export default {
  components: {
    WithLabel,
  },
  props: {
    label: {
      type: String,
      default: '',
    },
    name: {
      type: String,
      required: true,
    },
    required: {
      type: Boolean,
      default: false,
    },
    placeholder: {
      type: String,
      default: '',
    },
    value: {
      type: [String, Number],
      default: '',
    },
    rows: {
      type: Number,
      default: 3,
    },
    allowResize: {
      type: Boolean,
      default: true,
    },
    hasError: {
      type: Boolean,
      default: false,
    },
    errorMessage: {
      type: String,
      default: '',
    },
    dataTestid: {
      type: String,
      default: '',
    },
  },
  methods: {
    onInput(e) {
      this.$emit('input', e.target.value);
    },
  },
};
</script>
