<script>
import { getContrastingTextColor } from '@chatwoot/utils';

export default {
  props: {
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      default: '',
    },
    href: {
      type: String,
      default: '',
    },
    bgColor: {
      type: String,
      default: '',
    },
    small: {
      type: Boolean,
      default: false,
    },
    showClose: {
      type: Boolean,
      default: false,
    },
    icon: {
      type: String,
      default: '',
    },
    color: {
      type: String,
      default: '',
    },
    colorScheme: {
      type: String,
      default: '',
    },
    variant: {
      type: String,
      default: '',
    },
  },
  emits: ['remove'],
  computed: {
    textColor() {
      if (this.variant === 'smooth') return '';
      if (this.variant === 'dashed') return '';
      return this.color || getContrastingTextColor(this.bgColor);
    },
    labelClass() {
      return `label ${this.colorScheme} ${this.variant} ${
        this.small ? 'small' : ''
      }`;
    },
    labelStyle() {
      if (this.bgColor) {
        return {
          background: this.bgColor,
          color: this.textColor,
          border: `1px solid ${this.bgColor}`,
        };
      }
      return {};
    },
    anchorStyle() {
      if (this.bgColor) {
        return { color: this.textColor };
      }
      return {};
    },
  },
  methods: {
    onClick() {
      this.$emit('remove', this.title);
    },
  },
};
</script>

<template>
  <div
    class="inline-flex ltr:mr-1 rtl:ml-1 mb-1"
    :class="labelClass"
    :style="labelStyle"
    :title="description"
  >
    <span v-if="icon" class="label-action--button">
      <fluent-icon :icon="icon" size="12" class="label--icon cursor-pointer" />
    </span>
    <span
      v-if="['smooth', 'dashed'].includes(variant) && title && !icon"
      :style="{ background: color }"
      class="label-color-dot flex-shrink-0"
    />
    <span v-if="!href" class="whitespace-nowrap text-ellipsis overflow-hidden">
      {{ title }}
    </span>
    <a v-else :href="href" :style="anchorStyle">{{ title }}</a>
    <button
      v-if="showClose"
      class="label-close--button p-0"
      :style="{ color: textColor }"
      @click="onClick"
    >
      <fluent-icon icon="dismiss" size="12" class="close--icon" />
    </button>
  </div>
</template>

<style scoped lang="scss">
.label {
  @apply items-center font-medium text-xs rounded-[4px] gap-1 p-1 bg-s-subtle text-s-primary border border-solid border-s-border-strong h-6;

  &.small {
    @apply text-xs py-0.5 px-1 leading-tight h-5;
  }

  &.small .label--icon,
  &.small .close--icon {
    @apply text-[0.5rem];
  }

  a {
    @apply text-xs;
    &:hover {
      @apply underline;
    }
  }

  /* Color Schemes */
  &.primary {
    @apply bg-s-brand-soft text-s-brand-text border border-solid border-s-brand;

    a {
      @apply text-s-brand-text;
    }
    .label-color-dot {
      @apply bg-s-brand;
    }
  }
  &.secondary {
    @apply bg-s-border-subtle text-s-primary border border-solid border-s-border;

    a {
      @apply text-s-primary;
    }
    .label-color-dot {
      @apply bg-s-muted;
    }
  }
  &.success {
    @apply bg-s-success/30 text-s-success-text border border-solid border-s-border;

    a {
      @apply text-s-success-text;
    }
    .label-color-dot {
      @apply bg-s-success;
    }
  }
  &.alert {
    @apply bg-s-error-soft text-s-error-text border border-solid border-s-border;

    a {
      @apply text-s-error-text;
    }
    .label-color-dot {
      @apply bg-s-error;
    }
  }
  &.warning {
    @apply bg-s-warning-soft text-s-warning-text border border-solid border-s-border;

    a {
      @apply text-s-warning-text;
    }
    .label-color-dot {
      @apply bg-s-warning;
    }
  }

  &.smooth {
    @apply bg-transparent text-s-muted dark:text-s-primary border border-solid border-s-border-strong;
  }

  &.dashed {
    @apply bg-transparent text-s-muted dark:text-s-primary border border-dashed border-s-border-strong;
  }
}

.label-close--button {
  @apply text-s-muted -mb-0.5 rounded-sm cursor-pointer flex items-center justify-center hover:bg-s-subtle;

  svg {
    @apply text-s-muted;
  }
}

.label-action--button {
  @apply flex mr-1;
}

.label-color-dot {
  @apply inline-block w-3 h-3 rounded-sm shadow-sm;
}
.label.small .label-color-dot {
  @apply w-2 h-2 rounded-sm shadow-sm;
}
</style>
