<template>
  <div
    :class="labelClass"
    :style="{ background: bgColor, color: textColor }"
    :title="description"
  >
    <span v-if="!href">{{ title }}</span>
    <a v-else :href="href" :style="{ color: textColor }">{{ title }}</a>
    <i v-if="showIcon" class="label--icon" :class="icon" @click="onClick" />
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
      default: '#1f93ff',
    },
    small: {
      type: Boolean,
      default: false,
    },
    showIcon: {
      type: Boolean,
      default: false,
    },
    icon: {
      type: String,
      default: 'ion-close',
    },
  },
  computed: {
    textColor() {
      return getContrastingTextColor(this.bgColor);
    },
    labelClass() {
      return `label ${this.small ? 'small' : ''}`;
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
  display: inline-block;
  font-size: var(--font-size-mini);
  line-height: 1.4;
  margin: var(--space-micro);
  border-radius: var(--border-radius-medium);
  font-weight: var(--font-weight-medium);

  &.small {
    font-size: var(--font-size-mini);
  }

  a {
    &:hover {
      text-decoration: underline;
    }
  }
}

.label--icon {
  cursor: pointer;
  font-size: var(--font-size-micro);
  line-height: 1.5;
  margin-left: var(--space-smaller);
}
</style>
