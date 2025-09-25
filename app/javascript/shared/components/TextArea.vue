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
        'text-n-gray-12': !error,
        'text-n-ruby-9': error,
      }"
    >
      {{ label }}
    </div>
    <textarea
      v-model="computedModel"
      class="w-full px-3 py-2 leading-tight border rounded outline-none resize-none text-n-gray-12"
      :class="{
        'border-n-weak hover:border-n-weak focus:border-n-weak': !error,
        'border-n-ruby-9 hover:border-n-ruby-9 focus:border-n-ruby-9': error,
      }"
      :placeholder="placeholder"
    />
    <div v-if="error" class="mt-2 text-xs font-medium text-n-ruby-9">
      {{ error }}
    </div>
  </label>
</template>

<style lang="scss" scoped>
textarea {
  min-height: 8rem;
}
</style>
