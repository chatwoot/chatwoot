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
      const color = this.bgColor.replace('#', '');
      const r = parseInt(color.slice(0, 2), 16);
      const g = parseInt(color.slice(2, 4), 16);
      const b = parseInt(color.slice(4, 6), 16);
      // http://stackoverflow.com/a/3943023/112731
      return r * 0.299 + g * 0.587 + b * 0.114 > 186 ? '#000000' : '#FFFFFF';
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
  font-size: $font-size-small;
  line-height: 1;
  margin: $space-micro;

  &.small {
    font-size: $font-size-mini;
  }

  a {
    &:hover {
      text-decoration: underline;
    }
  }
}

.label--icon {
  cursor: pointer;
  font-size: $font-size-micro;
  line-height: 1.5;
  margin-left: $space-smaller;
}
</style>
