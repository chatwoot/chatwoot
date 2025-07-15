<script>
export default {
  props: {
    block: {
      type: Boolean,
      default: false,
    },
    type: {
      type: String,
      default: 'purple', // Alterado de 'blue' para 'purple'
    },
    bgColor: {
      type: String,
      default: '',
    },
    textColor: {
      type: String,
      default: '',
    },
    disabled: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    buttonClassName() {
      let className =
        'text-white py-3 px-6 rounded-xl shadow-elegant leading-4 cursor-pointer disabled:opacity-50 transition-all duration-200 font-medium transform hover:scale-105';
      
      if (this.type === 'clear') {
        className = 'flex mx-auto mt-4 text-xs leading-3 w-auto text-n-gray-12 hover:text-purple-600 transition-colors duration-200';
      }

      if (this.type === 'purple' && !Object.keys(this.buttonStyles).length) {
        className = `${className} bg-purple-600 hover:bg-purple-700 shadow-modern hover:shadow-luxury`;
      }

      if (this.type === 'blue' && !Object.keys(this.buttonStyles).length) {
        className = `${className} bg-blue-600 hover:bg-blue-700 shadow-modern`;
      }

      if (this.type === 'green' && !Object.keys(this.buttonStyles).length) {
        className = `${className} bg-teal-600 hover:bg-teal-700 shadow-modern`;
      }

      if (this.type === 'gold' && !Object.keys(this.buttonStyles).length) {
        className = `${className} bg-amber-500 hover:bg-amber-600 text-amber-900 shadow-modern`;
      }

      if (this.type === 'outline') {
        className = `py-3 px-6 rounded-xl border-2 border-purple-300 text-purple-700 hover:bg-purple-50 transition-all duration-200 font-medium cursor-pointer disabled:opacity-50`;
      }

      if (this.type === 'ghost') {
        className = `py-3 px-6 rounded-xl text-purple-600 hover:bg-purple-50 transition-all duration-200 font-medium cursor-pointer disabled:opacity-50`;
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
};
</script>

<template>
  <button 
    :class="buttonClassName" 
    :style="buttonStyles" 
    :disabled="disabled"
    class="focus:outline-none focus:ring-4 focus:ring-purple-200 focus:ring-opacity-50"
  >
    <slot />
  </button>
</template>
