<template>
  <button type="submit" :disabled="disabled" :class="computedClass">
    <i :class="iconClass" class="icon" v-if="!!iconClass"></i>
    <span>{{buttonText}}</span>
    <spinner v-if="loading"/>
  </button>
</template>

<script>
import Spinner from '../Spinner';

export default {
  props: {
    disabled: Boolean,
    loading: Boolean,
    buttonText: String,
    buttonClass: String,
    iconClass: String,
  },
  components: {
    Spinner,
  },
  computed: {
    computedClass() {
      return `button ${this.buttonClass || ' '}`;
    },
  },
};
</script>
