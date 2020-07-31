<template>
  <li class="option" :class="{ 'is-selected': isSelected }">
    <button class="option-button button" @click="onClick">
      <span v-if="isSelected" class="icon ion-checkmark-circled" />
      <span v-else class="icon ion-android-radio-button-off" />
      <span>{{ action.title }}</span>
    </button>
  </li>
</template>

<script>
export default {
  components: {},
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
  methods: {
    onClick() {
      this.$emit('click', this.action);
    },
  },
};
</script>

<style scoped lang="scss">
@import '~dashboard/assets/scss/variables.scss';
@import '~dashboard/assets/scss/mixins.scss';
.option {
  .option-button {
    width: 100%;
    padding: 0;
    max-height: $space-larger;
    border-radius: 0;
    background: transparent;
    color: $color-woot;
    border: 0;
    text-align: left;
    cursor: pointer;

    span {
      display: inline-block;
      vertical-align: middle;
    }

    > .icon {
      margin-right: $space-smaller;
      font-size: $font-size-medium;
    }
  }

  + .option .option-button {
    @include border-normal-top;
  }

  &.is-selected {
    .option-button {
      color: $success-color;
    }
  }
}
</style>
