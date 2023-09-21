<template>
  <button
    :type="type"
    data-testid="submit_button"
    :disabled="disabled"
    :class="computedClass"
    class="flex items-center w-full justify-center rounded-md bg-woot-500 py-3 px-3 text-base font-medium text-white shadow-sm hover:bg-woot-600 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-woot-500 cursor-pointer"
    @click="onClick"
  >
    <span>{{ buttonText }}</span>
    <fluent-icon v-if="!!iconClass" :icon="iconClass" class="icon" />
    <spinner v-if="loading" />
  </button>
</template>

<script>
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    Spinner,
  },
  props: {
    disabled: {
      type: Boolean,
      default: false,
    },
    loading: {
      type: Boolean,
      default: false,
    },
    buttonText: {
      type: String,
      default: '',
    },
    buttonClass: {
      type: String,
      default: '',
    },
    iconClass: {
      type: String,
      default: '',
    },
    type: {
      type: String,
      default: 'submit',
    },
  },
  computed: {
    computedClass() {
      return `
        ${this.disabled ? 'opacity-40 hover:bg-woot-500' : ''}
        ${this.buttonClass || ' '}
      `;
    },
  },
  methods: {
    onClick() {
      this.$emit('click');
    },
  },
};
</script>
