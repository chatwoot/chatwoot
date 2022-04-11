<template>
  <div :class="labelClass" :style="labelStyle" :title="description">
    <button v-if="icon" class="label-action--button" @click="onClick">
      <fluent-icon :icon="icon" size="12" class="label--icon" />
    </button>
    <span v-if="!href">{{ title }}</span>
    <a v-else :href="href" :style="anchorStyle">{{ title }}</a>
    <button
      v-if="showClose"
      class="label-action--button"
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
    colorScheme: {
      type: String,
      default: '',
    },
  },
  computed: {
    textColor() {
      return getContrastingTextColor(this.bgColor);
    },
    labelClass() {
      return `label ${this.colorScheme} ${this.small ? 'small' : ''}`;
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

  &.small {
    font-size: var(--font-size-micro);
  }

  .label--icon {
    cursor: pointer;
    margin-right: var(--space-smaller);
  }

  .close--icon {
    cursor: pointer;
    margin-left: var(--space-smaller);
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
  }
  &.secondary {
    background: var(--s-100);
    color: var(--s-900);
    border: 1px solid var(--s-200);
    a {
      color: var(--s-900);
    }
  }
  &.success {
    background: var(--g-100);
    color: var(--g-900);
    border: 1px solid var(--g-200);
    a {
      color: var(--g-900);
    }
  }
  &.alert {
    background: var(--r-100);
    color: var(--r-900);
    border: 1px solid var(--r-200);
    a {
      color: var(--r-900);
    }
  }
  &.warning {
    background: var(--y-100);
    color: var(--y-900);
    border: 1px solid var(--y-200);
    a {
      color: var(--y-900);
    }
  }
}

.label-action--button {
  margin-bottom: var(--space-minus-micro);
}
</style>
