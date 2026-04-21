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
        'text-s-primary': !error,
        'text-s-error': error,
      }"
    >
      {{ label }}
    </div>
    <textarea
      v-model="computedModel"
      class="w-full px-3 py-2 leading-tight border rounded outline-none resize-none text-s-primary"
      :class="{
        'border-s-border hover:border-s-border focus:border-s-border': !error,
        'border-s-error hover:border-s-error focus:border-s-error': error,
      }"
      :placeholder="placeholder"
    />
    <div v-if="error" class="mt-2 text-xs font-medium text-s-error">
      {{ error }}
    </div>
  </label>
</template>

<style lang="scss" scoped>
textarea {
  min-height: 8rem;
}
</style>
