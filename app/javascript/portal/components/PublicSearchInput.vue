<template>
  <div
    class="w-full flex items-center rounded-lg border-solid border h-12 bg-white dark:bg-slate-900 px-5 py-2 text-slate-600 dark:text-slate-200"
    :class="{
      'shadow border-woot-100 dark:border-woot-700': isFocused,
      'border-slate-50 dark:border-slate-800 shadow-sm': !isFocused,
    }"
  >
    <fluent-icon icon="search" />
    <input
      :value="value"
      type="text"
      class="w-full focus:outline-none text-base h-full bg-white dark:bg-slate-900 px-2 py-2 text-slate-700 dark:text-slate-100 placeholder-slate-500"
      :placeholder="searchPlaceholder"
      role="search"
      @input="onChange"
      @focus="onFocus"
      @blur="onBlur"
    />
  </div>
</template>

<script>
import FluentIcon from 'shared/components/FluentIcon/Index.vue';

export default {
  components: {
    FluentIcon,
  },
  props: {
    value: {
      type: [String, Number],
      default: '',
    },
    searchPlaceholder: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      isFocused: false,
    };
  },
  methods: {
    onChange(e) {
      this.$emit('input', e.target.value);
    },
    onFocus(e) {
      this.isFocused = true;
      this.$emit('focus', e.target.value);
    },
    onBlur(e) {
      this.isFocused = false;
      this.$emit('blur', e.target.value);
    },
  },
};
</script>
