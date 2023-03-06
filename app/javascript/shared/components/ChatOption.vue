<template>
  <div
    class="option"
    :class="optionClass"
    :style="{ borderColor: widgetColor, color: widgetColor }"
  >
    <button class="option-button button" @click="onClick">
      <span :style="{ color: widgetColor }">{{ action.title }}</span>
    </button>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import darkModeMixin from 'widget/mixins/darkModeMixin.js';

export default {
  components: {},
  mixins: [darkModeMixin],
  props: {
    action: {
      type: Object,
      default: () => {},
    },
    isSelected: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    optionClass() {
      let optionClass = `${this.$dm('bg-white', 'dark:bg-slate-700')}`;
      if (this.isSelected) optionClass = 'is-selected ' + optionClass;
      return optionClass;
    },
  },
  methods: {
    onClick() {
      this.$emit('click', this.action);
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';
@import '~widget/assets/scss/mixins.scss';

.option {
  @include light-shadow;
  border-radius: $space-jumbo;
  border: 1px solid $color-woot;
  margin: $space-smaller;
  max-width: 100%;

  .option-button {
    background: transparent;
    border-radius: $space-large;
    border: 0;
    cursor: pointer;
    height: auto;
    line-height: 1.5;
    min-height: $space-two * 2;
    text-align: left;
    white-space: normal;

    span {
      display: inline-block;
      vertical-align: middle;
      font-weight: $font-weight-bold;
      white-space: nowrap;
    }

    > .icon {
      margin-right: $space-smaller;
      font-size: $font-size-medium;
    }
  }
}
</style>
