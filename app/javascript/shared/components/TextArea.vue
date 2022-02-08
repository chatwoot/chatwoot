<template>
  <label class="block">
    <div
      v-if="label"
      class="mb-2 text-xs font-medium"
      :class="{
        'text-black-800': !error,
        'text-red-400': error,
      }"
    >
      {{ label }}
    </div>
    <textarea
      class="
        resize-none
        border
        rounded
        w-full
        py-2
        px-3
        text-slate-700
        leading-tight
        outline-none
      "
      :class="{
        'border-black-200 hover:border-black-300 focus:border-black-300': !error,
        'border-red-200 hover:border-red-300 focus:border-red-300': error,
      }"
      :placeholder="placeholder"
      :value="value"
      @change="onChange"
    />
    <div v-if="error" class="text-red-400 mt-2 text-xs font-medium">
      {{ error }}
    </div>
  </label>
</template>
<script>
export default {
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
