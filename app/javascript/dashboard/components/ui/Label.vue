<template>
  <div :class="labelClass" :style="labelStyle" :title="description">
    <span v-if="icon" class="label-action--button">
      <fluent-icon :icon="icon" size="12" class="label--icon" />
    </span>
    <span
      v-if="variant === 'smooth'"
      :style="{ background: color }"
      class="label-color-dot"
    />
    <span v-if="!href">{{ title }}</span>
    <a v-else :href="href" :style="anchorStyle">{{ title }}</a>
    <button
      v-if="showClose"
      class="label-close--button "
      :style="{ color: textColor }"
      @click="onClick"
    >
      <fluent-icon icon="dismiss" size="12" class="close--icon" />
    </button>
  </div>
</template>
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
  computed: {
    textColor() {
      if (this.variant === 'smooth') return '';
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
      this.$emit('click', this.title);
    },
  },
};
</script>

<style scoped lang="scss">
@import '~dashboard/assets/scss/variables';

.label {
  display: inline-flex;
  align-items: center;
  font-weight: var(--font-weight-medium);
  margin-right: var(--space-smaller);
  margin-bottom: var(--space-smaller);
  padding: var(--space-smaller);
  background: var(--s-50);
  color: var(--s-800);
  border: 1px solid var(--s-75);
  height: var(--space-medium);

  &.small {
    font-size: var(--font-size-micro);
    padding: var(--space-micro) var(--space-smaller);
    line-height: 1.2;
    letter-spacing: 0.15px;
  }

  .label--icon {
    cursor: pointer;
    margin-right: var(--space-smaller);
  }

  &.small .label--icon,
  &.small .close--icon {
    font-size: var(--font-size-nano);
  }

  a {
    font-size: var(--font-size-mini);
    &:hover {
      text-decoration: underline;
    }
  }

  /* Color Schemes */
  &.primary {
    background: var(--w-100);
    color: var(--w-900);
    border: 1px solid var(--w-200);
    a {
      color: var(--w-900);
    }
    .label-color-dot {
      background: var(--w-600);
    }
  }
  &.secondary {
    background: var(--s-100);
    color: var(--s-900);
    border: 1px solid var(--s-200);
    a {
      color: var(--s-900);
    }
    .label-color-dot {
      background: var(--s-600);
    }
  }
  &.success {
    background: var(--g-100);
    color: var(--g-900);
    border: 1px solid var(--g-200);
    a {
      color: var(--g-900);
    }
    .label-color-dot {
      background: var(--g-600);
    }
  }
  &.alert {
    background: var(--r-100);
    color: var(--r-900);
    border: 1px solid var(--r-200);
    a {
      color: var(--r-900);
    }
    .label-color-dot {
      background: var(--r-600);
    }
  }
  &.warning {
    background: var(--y-100);
    color: var(--y-900);
    border: 1px solid var(--y-200);
    a {
      color: var(--y-900);
    }
    .label-color-dot {
      background: var(--y-900);
    }
  }

  &.smooth {
    background: transparent;
    border: 1px solid var(--s-75);
    color: var(--s-800);
  }
}

.label-close--button {
  color: var(--s-800);
  margin-bottom: var(--space-minus-micro);
  margin-left: var(--space-smaller);
  border-radius: var(--border-radius-small);
  cursor: pointer;

  display: flex;
  justify-content: center;
  align-items: center;

  &:hover {
    background: var(--s-100);
  }
}

.label-action--button {
  margin-bottom: var(--space-minus-micro);
}

.label-color-dot {
  display: inline-block;
  width: var(--space-one);
  height: var(--space-one);
  border-radius: var(--border-radius-small);
  margin-right: var(--space-smaller);
}
</style>
