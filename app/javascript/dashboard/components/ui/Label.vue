<template>
  <div :class="labelClass" :style="labelStyle" :title="description">
    <i v-if="icon" class="label--icon" :class="icon" @click="onClick" />
    <span v-if="!href">{{ title }}</span>
    <a v-else :href="href" :style="anchorStyle">{{ title }}</a>
    <i v-if="showClose" class="close--icon ion-close" @click="onClick" />
  </div>
</template>
<script>
import { getContrastingTextColor } from 'shared/helpers/ColorHelper';
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
        return { background: this.bgColor, color: this.textColor };
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
  font-weight: var(--font-weight-medium);
  margin-right: var(--space-smaller);
  margin-bottom: var(--space-smaller);

  &.small {
    font-size: var(--font-size-micro);
  }

  .label--icon {
    cursor: pointer;
  }
  .label--icon,
  .close--icon {
    font-size: var(--font-size-micro);
    cursor: pointer;
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
    border: 1px solid var(--y-300);
    a {
      color: var(--y-900);
    }
  }
}
</style>
