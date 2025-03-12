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
  created() {
    // eslint-disable-next-line
    console.warn(
      '[DEPRECATED] This component has been deprecated and will be removed soon. Please use v3/components/Form/Button.vue instead'
    );
  },
};
</script>

<template>
  <button
    :type="type"
    data-testid="submit_button"
    :disabled="disabled"
    :class="computedClass"
    class="flex items-center w-full justify-center rounded-md bg-woot-500 py-3 px-3 text-base font-medium text-white shadow-sm hover:bg-woot-600 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-woot-500 cursor-pointer"
  >
    <span>{{ buttonText }}</span>
    <fluent-icon v-if="!!iconClass" :icon="iconClass" class="icon" />
    <Spinner v-if="loading" />
  </button>
</template>
