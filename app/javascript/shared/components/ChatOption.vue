<script>
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';

export default {
  components: {},
  mixins: [],
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
  emits: ['optionSelect'],
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
      this.$emit('optionSelect', this.action);
    },
  },
};
</script>

<template>
  <div
    class="option"
    :class="optionClass"
    :style="{ borderColor: widgetColor, color: widgetColor }"
  >
    <button class="option-button button" @click="onClick">
      <span v-if="action.image_url" class="icon">
        <img :src="action.image_url" alt="icon" />
      </span>
      <span :style="{ color: widgetColor }">{{ action.title }}</span>
    </button>
  </div>
</template>

<style scoped lang="scss">
@import 'widget/assets/scss/_variables.scss';
@import 'dashboard/assets/scss/_mixins.scss';

.option {
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  border-radius: $space-jumbo;
  border: 1px solid $color-woot;
  margin: $space-smaller;
  max-width: 100%;
  transform: translateY(0px);

  &:hover {
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
    transform: translateY(-2px);
  }

  .option-button {
    background: transparent;
    border-radius: $space-large;
    border: 0;
    cursor: pointer;
    height: auto;
    line-height: 1.5;
    min-height: $space-two * 2;
    text-align: left;
    white-space: nowrap;

    span {
      display: inline-block;
      vertical-align: middle;
      white-space: nowrap;
    }

    > .icon {
      font-size: $font-size-medium;
      width: 24px;
    }
  }
}
</style>
