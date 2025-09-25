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
  <div
    class="chat-bubble agent max-w-64 !py-2 !px-4 rounded-lg overflow-hidden mt-1 bg-n-background dark:bg-n-solid-3"
  >
    <h4 class="text-n-slate-12 text-sm font-normal my-1 leading-[1.5]">
      <div
        v-dompurify-html="formatMessage(title, false)"
        class="text-n-slate-12"
      />
    </h4>
    <ul v-if="!hideFields" class="w-full">
      <ChatOption
        v-for="option in options"
        :key="option.id"
        :action="option"
        :is-selected="isSelected(option)"
        class="list-none p-0"
        @option-select="onClick"
      />
    </ul>
  </div>
</template>
