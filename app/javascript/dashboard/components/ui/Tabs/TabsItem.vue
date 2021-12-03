<template>
  <li
    :class="{
      'tabs-title': true,
      'is-active': active,
      [variant]: variant,
    }"
  >
    <woot-button
      :size="size"
      :variant="buttonVariant"
      :color-scheme="colorScheme"
      :is-rounded="isRounded"
      @click="onTabClick"
    >
      {{ name }}
      <span v-if="showBadge" class="badge">
        {{ getItemCount }}
      </span>
    </woot-button>
  </li>
</template>
<script>
import TWEEN from 'tween.js';

export default {
  name: 'WootTabsItem',
  props: {
    index: {
      type: Number,
      default: 0,
    },
    name: {
      type: String,
      required: true,
    },
    disabled: {
      type: Boolean,
      default: false,
    },
    count: {
      type: Number,
      default: 0,
    },
    showBadge: {
      type: Boolean,
      default: true,
    },
    variant: {
      type: String,
      default: '',
      // Available variants: [ '', 'smooth']
    },
    size: {
      type: String,
      default: '',
    },
  },

  data() {
    return {
      animatedNumber: 0,
    };
  },

  computed: {
    active() {
      return this.index === this.$parent.index;
    },

    getItemCount() {
      return this.animatedNumber || this.count;
    },
    colorScheme() {
      if (this.variant === 'smooth') return 'secondary';
      return this.active ? '' : 'secondary';
    },
    buttonVariant() {
      if (this.variant === 'smooth') return this.active ? 'smooth' : 'clear';
      return 'clear';
    },
    isRounded() {
      return this.variant === 'smooth';
    },
  },

  watch: {
    count(newValue, oldValue) {
      let animationFrame;
      const animate = time => {
        TWEEN.update(time);
        animationFrame = window.requestAnimationFrame(animate);
      };
      const tweeningNumber = { value: oldValue };
      new TWEEN.Tween(tweeningNumber)
        .easing(TWEEN.Easing.Quadratic.Out)
        .to({ value: newValue }, 500)
        .onUpdate(() => {
          this.animatedNumber = tweeningNumber.value.toFixed(0);
        })
        .onComplete(() => {
          window.cancelAnimationFrame(animationFrame);
        })
        .start();
      animationFrame = window.requestAnimationFrame(animate);
    },
  },
  methods: {
    onTabClick(event) {
      event.preventDefault();
      if (!this.disabled) {
        this.$parent.$emit('change', this.index);
      }
    },
  },
};
</script>
