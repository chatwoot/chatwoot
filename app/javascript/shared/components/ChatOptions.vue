<template>
  <div class="options-message chat-bubble agent">
    <div class="card-body">
      <h4 class="title">
        {{ title }}
      </h4>
      <ul class="options" :class="{ 'has-selected': !!selected }">
        <chat-option
          v-for="option in options"
          :key="option.id"
          :action="option"
          :is-selected="isSelected(option)"
        />
      </ul>
    </div>
  </div>
</template>

<script>
import ChatOption from 'shared/components/ChatOption';

export default {
  components: {
    ChatOption,
  },
  props: {
    title: {
      type: String,
      default: '',
    },
    options: {
      type: Array,
      default: () => [],
    },
    selected: {
      type: String,
      default: '',
    },
  },
  methods: {
    isSelected(option) {
      return this.selected === option.id;
    },
  },
};
</script>

<style lang="scss">
@import '~dashboard/assets/scss/variables.scss';
.has-selected {
  .option-button:not(.is-selected) {
    color: $color-light-gray;
    cursor: initial;
  }
}
</style>
<style scoped lang="scss">
@import '~dashboard/assets/scss/variables.scss';
@import '~dashboard/assets/scss/mixins.scss';

.options-message {
  @include border-normal;
  background: white;
  width: 60%;
  max-width: 17rem;
  padding: $space-small $space-normal;
  border-radius: $space-small;
  overflow: hidden;

  .title {
    font-size: $font-size-small;
    font-weight: $font-weight-normal;
    margin-top: $space-smaller;
    margin-bottom: $space-smaller;
    color: $color-heading;
    line-height: 1.5;
  }

  .options {
    width: 100%;

    > li {
      list-style: none;
      padding: 0;
      margin: 0;
    }
  }
}
</style>
