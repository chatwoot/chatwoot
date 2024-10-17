<script>
import ChatOption from 'shared/components/ChatOption.vue';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

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
    hideFields: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['optionSelect'],
  setup() {
    const { formatMessage } = useMessageFormatter();
    return {
      formatMessage,
    };
  },
  methods: {
    isSelected(option) {
      return this.selected === option.id;
    },
    onClick(selectedOption) {
      this.$emit('optionSelect', selectedOption);
    },
  },
};
</script>

<template>
  <div class="options-message chat-bubble agent bg-white dark:bg-slate-700">
    <div class="card-body">
      <h4 class="title text-black-900 dark:text-slate-50">
        <div
          v-dompurify-html="formatMessage(title, false)"
          class="message-content text-black-900 dark:text-slate-50"
        />
      </h4>
      <ul
        v-if="!hideFields"
        class="options"
        :class="{ 'has-selected': !!selected }"
      >
        <ChatOption
          v-for="option in options"
          :key="option.id"
          :action="option"
          :is-selected="isSelected(option)"
          @option-select="onClick"
        />
      </ul>
    </div>
  </div>
</template>

<style lang="scss">
@import 'dashboard/assets/scss/variables.scss';

.has-selected {
  .option-button:not(.is-selected) {
    color: $color-light-gray;
    cursor: initial;
  }
}
</style>

<style scoped lang="scss">
@import 'widget/assets/scss/variables.scss';

.options-message {
  max-width: 17rem;
  padding: $space-small $space-normal;
  border-radius: $space-small;
  overflow: hidden;

  .title {
    font-size: $font-size-default;
    font-weight: $font-weight-normal;
    margin-top: $space-smaller;
    margin-bottom: $space-smaller;
    line-height: 1.5;
  }

  .options {
    width: 100%;

    > li {
      list-style: none;
      padding: 0;
    }
  }
}
</style>
