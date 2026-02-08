<script>
export default {
  props: {
    label: {
      type: String,
      default: '',
    },
    placeholder: {
      type: String,
      default: '',
    },
    modelValue: {
      type: [String, Number],
      required: true,
    },
    error: {
      type: String,
      default: '',
    },
  },
  emits: ['update:modelValue'],
  computed: {
    computedModel: {
      get() {
        return this.modelValue;
      },
      set(value) {
        this.$emit('update:modelValue', value);
      },
    },
  },
};
</script>

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
      v-model="computedModel"
      class="w-full px-3 py-2 leading-tight border rounded outline-none resize-none text-slate-700"
      :class="{
        'border-black-200 hover:border-black-300 focus:border-black-300':
          !error,
        'border-red-200 hover:border-red-300 focus:border-red-300': error,
      }"
      :placeholder="placeholder"
    />
    <div v-if="error" class="mt-2 text-xs font-medium text-red-400">
      {{ error }}
    </div>
  </label>
</template>

<style lang="scss" scoped>
textarea {
  min-height: 8rem;
}
</style>
