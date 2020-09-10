<template>
  <button :class="buttonClassName" :style="buttonStyles" @click="onClick">
    <slot></slot>
  </button>
</template>
<script>
export default {
  props: {
    block: {
      type: Boolean,
      default: false,
    },
    type: {
      type: String,
      default: 'blue',
    },
    bgColor: {
      type: String,
      default: '',
    },
    textColor: {
      type: String,
      default: '',
    },
  },
  computed: {
    buttonClassName() {
      let className = 'text-white py-3 px-4 rounded shadow-sm';
      if (this.type === 'blue' && !Object.keys(this.buttonStyles).length) {
        className = `${className} bg-woot-500 hover:bg-woot-700`;
      }
      if (this.block) {
        className = `${className} w-full`;
      }
      return className;
    },
    buttonStyles() {
      const styles = {};
      if (this.bgColor) {
        styles.backgroundColor = this.bgColor;
      }
      if (this.textColor) {
        styles.color = this.textColor;
      }
      return styles;
    },
  },
  methods: {
    onClick(e) {
      this.$emit('click', e);
    },
  },
};
</script>
