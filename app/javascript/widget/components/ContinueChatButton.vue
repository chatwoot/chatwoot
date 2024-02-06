<template>
  <button
    type="button"
    class="flex w-full justify-between items-center rounded-md ring-1 ring-inset ring-slate-50 px-2 py-2 text-sm text-slate-700 bg-slate-25 hover:bg-slate-50 dark:text-white dark:bg-slate-800 dark:ring-slate-900 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-woot-600 group"
    @click="$emit('continue')"
  >
    <div
      class="w-10 h-10 rounded-md bg-slate-75 dark:bg-slate-700 text-lg flex items-center justify-center flex-shrink-0"
    >
      <fluent-icon
        icon="chat"
        size="16"
        class="text-slate-600 dark:text-slate-400"
      />
    </div>
    <div
      class="text-left flex flex-col justify-start flex-grow max-w-[calc(100%-80px)] mx-2 group-hover:opacity-75"
    >
      <h5 class="font-medium text-slate-900 dark:text-white">
        {{ title }}
      </h5>
      <p class="h-4 leading-4 flex items-center gap-1">
        <span
          v-if="unreadCount > 0"
          class="inline-flex items-center justify-center rounded-full bg-green-200 px-1 min-w-[16px] leading-4 text-xxs font-medium text-green-700 mr-0.5"
        >
          {{ unreadCount }}
        </span>
        <span
          v-dompurify-html="content"
          class="leading-4 h-4 text-ellipsis overflow-hidden whitespace-nowrap dark:text-slate-25"
        />
      </p>
    </div>
    <div class="w-8 h-10 flex items-center justify-center">
      <fluent-icon icon="chevron-right" />
    </div>
  </button>
</template>

<script>
import FluentIcon from 'shared/components/FluentIcon/Index.vue';

export default {
  components: { FluentIcon },
  props: {
    title: {
      type: String,
      default: 'Continue your chat',
    },
    content: {
      type: String,
      default: 'Chat with us',
    },
    unreadCount: {
      type: Number,
      default: 0,
    },
  },
};
</script>
