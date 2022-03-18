<template>
  <div class="relative">
    <button class="z-10 focus:outline-none select-none" @click="toggleMenu">
      <slot name="button"></slot>
    </button>

    <!-- to close when clicked on space around it-->
    <button
      v-if="isOpen"
      tabindex="-1"
      class="fixed inset-0 h-full w-full cursor-default focus:outline-none"
      @click="toggleMenu"
    ></button>

    <!--dropdown menu-->
    <transition
      enter-active-class="transition-all duration-200 ease-out"
      leave-active-class="transition-all duration-750 ease-in"
      enter-class="opacity-0 scale-75"
      enter-to-class="opacity-100 scale-100"
      leave-class="opacity-100 scale-100"
      leave-to-class="opacity-0 scale-75"
    >
      <div
        v-if="isOpen"
        class="menu-content absolute shadow-xl rounded-md border-solid border border-slate-100 mt-1 py-1 px-2 bg-white z-10"
        :class="menuPlacement === 'right' ? 'right-0' : 'left-0'"
      >
        <slot name="content"></slot>
      </div>
    </transition>
  </div>
</template>

<script>
export default {
  props: {
    menuPlacement: {
      type: String,
      default: 'right',
      validator: value => ['right', 'left'].indexOf(value) !== -1,
    },
    open: {
      type: Boolean,
      default: false,
    },
    toggleMenu: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {
      isOpen: false,
    };
  },
  watch: {
    open() {
      this.isOpen = !this.isOpen;
    },
  },
  mounted() {
    document.addEventListener('keydown', this.onEscape);
  },
  beforeDestroy() {
    document.removeEventListener('keydown', this.onEscape);
  },
  methods: {
    onEscape(e) {
      if (e.key === 'Esc' || e.key === 'Escape') {
        this.isOpen = false;
      }
    },
  },
};
</script>
<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.menu-content {
  width: max-content;
}
</style>
