<script>
export default {
  props: {
    modelValue: { type: Boolean, default: false },
  },
  emits: ['update:modelValue'],
  methods: {
    onClick() {
      this.$emit('update:modelValue', !this.modelValue);
    },
  },
};
</script>

<template>
  <button
    type="button"
    class="relative flex-shrink-0 h-4 p-0 border-none shadow-inner w-7 rounded-3xl"
    :class="
      modelValue
        ? 'bg-primary-600 shadow-primary-800'
        : 'shadow-ash-400 bg-ash-200'
    "
    role="switch"
    :aria-checked="modelValue.toString()"
    @click="onClick"
  >
    <span
      aria-hidden="true"
      class="rounded-full bg-white top-0.5 absolute dark:bg-white w-3 h-3 translate-y-0 duration-200 transition-transform ease-in-out"
      :class="
        modelValue
          ? 'ltr:translate-x-0 rtl:translate-x-[0.75rem]'
          : 'ltr:-translate-x-[0.75rem] rtl:translate-x-0'
      "
    />
  </button>
</template>
