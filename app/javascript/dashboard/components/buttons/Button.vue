<template>
  <button :type="type" class="button nice" :class="variant" @click="onClick">
    <fluent-icon
      v-if="!isLoading && icon"
      class="icon"
      :class="buttonIconClass"
      :icon="icon"
    />
    <spinner v-if="isLoading" />
    <slot></slot>
  </button>
</template>

<script>
export default {
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
  methods: {
    onClick(e) {
      this.$emit('click', e);
    },
  },
};
</script>
