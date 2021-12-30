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

  computed: {
    active() {
      return this.index === this.$parent.index;
    },

    getItemCount() {
      return this.count;
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
