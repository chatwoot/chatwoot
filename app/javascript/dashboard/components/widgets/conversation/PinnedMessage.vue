<script>
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { useTimeAgo } from '@vueuse/core';
import { computed } from 'vue';

export default {
  props: {
    message: {
      type: Object,
      required: true,
    },
  },
  emits: ['unpin', 'click'],
  setup(props) {
    const { getPlainText } = useMessageFormatter();
    const timeAgo = useTimeAgo(props.message.created_at * 1000);
    const plainTextContent = computed(() =>
      getPlainText(props.message.content)
    );

    return {
      plainTextContent,
      timeAgo,
    };
  },
  methods: {
    handleUnpin() {
      this.$emit('unpin');
    },
    handleClick() {
      this.$emit('click', this.message.id);
    },
  },
};
</script>

<template>
  <div
    class="flex items-center justify-between px-4 py-2 mx-2 mt-2 bg-white border rounded-md shadow-sm border-n-weak dark:bg-n-solid-3 dark:border-n-solid-3 cursor-pointer hover:bg-n-alpha-1 dark:hover:bg-n-solid-2 transition-colors"
    @click="handleClick"
  >
    <div class="flex items-center gap-3 overflow-hidden">
      <div
        class="flex items-center justify-center flex-shrink-0 w-8 h-8 rounded bg-n-alpha-2 text-n-slate-11 dark:bg-n-solid-2"
      >
        <fluent-icon icon="pin" size="16" />
      </div>
      <div class="flex flex-col overflow-hidden">
        <div class="flex items-center gap-2">
          <span class="text-xs font-semibold text-n-slate-12">
            {{ $t('CONVERSATION.PINNED_MESSAGE') }}
          </span>
          <span class="text-xs text-n-slate-10">•</span>
          <span class="text-xs text-n-slate-10">
            {{ message.sender ? message.sender.name : '' }}
          </span>
          <span class="text-xs text-n-slate-10">•</span>
          <span class="text-xs text-n-slate-10">{{ timeAgo }}</span>
        </div>
        <span class="text-sm truncate text-n-slate-11">
          {{ plainTextContent }}
        </span>
      </div>
    </div>
    <button
      class="p-1 rounded hover:bg-n-alpha-2 text-n-slate-10 hover:text-n-slate-12 transition-colors flex-shrink-0"
      @click.stop="handleUnpin"
    >
      <fluent-icon icon="dismiss" size="14" />
    </button>
  </div>
</template>
