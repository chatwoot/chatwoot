<template>
  <button
    class="inline-flex items-center gap-1 text-sm font-medium reset-base rounded-xl w-fit"
    :type="type"
    :class="buttonClasses"
    :disabled="isDisabled"
    @click="handleClick"
  >
    <fluent-icon
      v-if="icon && !iconOnly"
      :size="iconSize"
      :icon="icon"
      class="flex-shrink-0"
    />
    <span
      v-if="$slots.default && !iconOnly"
      class="text-sm font-medium truncate"
      :class="{ 'text-left rtl:text-right': size !== 'expanded' }"
    >
      <slot />
    </span>
    <fluent-icon
      v-if="rightIcon || iconOnly"
      :size="iconSize"
      icon="chevron-right"
      class="flex-shrink-0"
    />
  </button>
</template>
<script>
export default {
  props: {
    type: {
      type: String,
      default: 'submit',
    },
    variant: {
      type: String,
      default: '',
    },
    size: {
      type: String,
      default: '',
    },
    icon: {
      type: String,
      default: '',
    },
    colorScheme: {
      type: String,
      default: 'primary',
    },
    classNames: {
      type: [String, Object],
      default: '',
    },
    isDisabled: {
      type: Boolean,
      default: false,
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
    isExpanded: {
      type: Boolean,
      default: false,
    },
    rightIcon: {
      type: Boolean,
      default: false,
    },
    iconOnly: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    buttonClasses() {
      return [this.colorClass, this.sizeClass];
    },
    colorClass() {
      if (this.isDisabled) {
        return 'bg-ash-200 text-ash-600 cursor-not-allowed';
      }
      if (this.colorScheme === 'primary') {
        if (this.variant === 'outline') {
          return 'text-primary-800 border  border-primary-400 hover:text-primary-600 active:text-primary-600 focus:ring focus:ring-offset-1 focus:ring-primary-400';
        }
        if (this.variant === 'ghost') {
          return 'text-primary-800 hover:text-primary-600 active:text-primary-600 focus:ring focus:ring-offset-1 focus:ring-primary-400';
        }
        return 'bg-primary-600 border-primary-600 text-white hover:bg-primary-700 active:bg-primary-700 focus:ring focus:ring-offset-1 focus:ring-primary-400';
      }
      if (this.colorScheme === 'secondary') {
        return 'bg-ash-100 text-ash-900 hover:bg-ash-200 active:bg-ash-200 focus:ring focus:ring-offset-1 focus:ring-ash-400';
      }
      if (this.colorScheme === 'danger') {
        return 'bg-ruby-600 text-white hover:bg-ruby-700 active:bg-ruby-700 focus:ring focus:ring-offset-1 focus:ring-ruby-400';
      }
      return 'bg-primary-500 text-white';
    },
    sizeClass() {
      if (this.size === 'medium') {
        return 'px-3 py-2 text-sm';
      }
      return 'px-4 py-2.5 text';
    },
    iconSize() {
      switch (this.size) {
        case 'medium':
          return 16;
        case 'large':
          return 18;

        default:
          return 16;
      }
    },
    showDarkSpinner() {
      return (
        this.colorScheme === 'secondary' ||
        this.variant === 'clear' ||
        this.variant === 'link' ||
        this.variant === 'hollow'
      );
    },
  },
  methods: {
    handleClick(evt) {
      this.$emit('click', evt);
    },
  },
};
</script>
