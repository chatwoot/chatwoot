<template>
  <button
    type="button"
    class="relative flex-shrink-0 h-4 p-0 border-none shadow-inner w-7 rounded-3xl"
    :class="
      value ? 'bg-primary-600 shadow-primary-800' : 'shadow-ash-400 bg-ash-200'
    "
    role="switch"
    :aria-checked="value.toString()"
    @click="onClick"
  >
    <span
      aria-hidden="true"
      class="rounded-full bg-white top-0.5 absolute dark:bg-white w-3 h-3 translate-y-0 duration-200 transition-transform ease-in-out"
      :class="
        value
          ? 'ltr:translate-x-0 rtl:translate-x-[12px]'
          : 'ltr:-translate-x-[12px] rtl:translate-x-0'
      "
    />
  </button>
</template>

<script>
export default {
  props: {
    value: { type: Boolean, default: false },
  },
  methods: {
    onClick() {
      this.$emit('input', !this.value);
    },
  },
};
</script>
