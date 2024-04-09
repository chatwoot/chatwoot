<template>
  <with-label
    :label="label"
    :icon="icon"
    :name="name"
    :has-error="hasError"
    :error-message="errorMessage"
  >
    <template #rightOfLabel>
      <slot />
    </template>
    <input
      :id="name"
      :name="name"
      :type="type"
      autocomplete="off"
      :tabindex="tabindex"
      :required="required"
      :placeholder="placeholder"
      :data-testid="dataTestid"
      :value="value"
      :class="{
        'focus:outline-red-600 outline-red-600 dark:focus:outline-red-600 dark:outline-red-600':
          hasError,
        'outline-slate-200 dark:outline-slate-600 dark:focus:outline-woot-500 focus:outline-woot-500':
          !hasError,
        'px-3 py-3': spacing === 'base',
        'px-3 py-2 mb-0': spacing === 'compact',
        'pl-9': icon,
      }"
      class="block w-full border-none rounded-md shadow-sm appearance-none outline outline-1 focus:outline-2 text-slate-900 dark:text-slate-100 placeholder:text-slate-400 sm:text-sm sm:leading-6 dark:bg-slate-800"
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
    type: {
      type: String,
      default: 'text',
    },
    tabindex: {
      type: Number,
      default: undefined,
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
    icon: {
      type: String,
      default: '',
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
    spacing: {
      type: String,
      default: 'base',
      validator: value => ['base', 'compact'].includes(value),
    },
  },
  methods: {
    onInput(e) {
      this.$emit('input', e.target.value);
    },
  },
};
</script>
