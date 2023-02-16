<template>
  <div
    class="w-full flex items-center rounded-md border-solid  h-16 bg-white px-4 py-2 text-slate-600"
    :class="{
      'shadow border-2 border-woot-100': isFocused,
      'border border-slate-50 shadow-sm': !isFocused,
    }"
  >
    <fluent-icon icon="search" />
    <input
      :value="value"
      type="text"
      class="w-full search-input focus:outline-none text-base h-full bg-white px-2 py-2
    text-slate-700 placeholder-slate-500 sm:text-sm"
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
