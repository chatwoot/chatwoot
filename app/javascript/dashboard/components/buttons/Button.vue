<script>
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    Spinner,
  },
  props: {
    isLoading: {
      type: Boolean,
      default: false,
    },
    icon: {
      type: String,
      default: '',
    },
    buttonIconClass: {
      type: String,
      default: '',
    },
    type: {
      type: String,
      default: 'button',
    },
    variant: {
      type: String,
      default: 'primary',
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
  <button :type="type" class="button nice" :class="variant">
    <fluent-icon
      v-if="!isLoading && icon"
      class="icon"
      :class="buttonIconClass"
      :icon="icon"
    />
    <Spinner v-if="isLoading" />
    <slot />
  </button>
</template>
