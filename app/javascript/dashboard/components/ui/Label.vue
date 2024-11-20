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
  @apply items-center font-medium text-xs rounded-[4px] gap-1 p-1 bg-slate-50 dark:bg-slate-700 text-slate-800 dark:text-slate-100 border border-solid border-slate-75 dark:border-slate-600 h-6;

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
    @apply bg-woot-100 dark:bg-woot-100 text-woot-900 dark:text-woot-900 border border-solid border-woot-200;

    a {
      @apply text-woot-900 dark:text-woot-900;
    }
    .label-color-dot {
      @apply bg-woot-600 dark:bg-woot-600;
    }
  }
  &.secondary {
    @apply bg-slate-100 dark:bg-slate-700 text-slate-900 dark:text-slate-100 border border-solid border-slate-200 dark:border-slate-600;

    a {
      @apply text-slate-900 dark:text-slate-100;
    }
    .label-color-dot {
      @apply bg-slate-600 dark:bg-slate-600;
    }
  }
  &.success {
    @apply bg-green-100 dark:bg-green-700 text-green-900 dark:text-green-100 border border-solid border-green-200 dark:border-green-600;

    a {
      @apply text-green-900 dark:text-green-100;
    }
    .label-color-dot {
      @apply bg-green-600 dark:bg-green-600;
    }
  }
  &.alert {
    @apply bg-red-100 dark:bg-red-700 text-red-900 dark:text-red-100 border border-solid border-red-200 dark:border-red-600;

    a {
      @apply text-red-900 dark:text-red-100;
    }
    .label-color-dot {
      @apply bg-red-600 dark:bg-red-600;
    }
  }
  &.warning {
    @apply bg-yellow-100 dark:bg-yellow-700 text-yellow-900 dark:text-yellow-100 border border-solid border-yellow-200 dark:border-yellow-600;

    a {
      @apply text-yellow-900 dark:text-yellow-100;
    }
    .label-color-dot {
      @apply bg-yellow-900 dark:bg-yellow-900;
    }
  }

  &.smooth {
    @apply bg-transparent text-slate-700 dark:text-slate-100 border border-solid border-slate-100 dark:border-slate-700;
  }

  &.dashed {
    @apply bg-transparent text-slate-700 dark:text-slate-100 border border-dashed border-slate-100 dark:border-slate-700;
  }
}

.label-close--button {
  @apply text-slate-800 dark:text-slate-100 -mb-0.5 rounded-sm cursor-pointer flex items-center justify-center hover:bg-slate-100 dark:hover:bg-slate-700;
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
