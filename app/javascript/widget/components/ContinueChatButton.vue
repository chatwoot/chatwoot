<template>
  <button
    type="button"
    class="flex w-full justify-between items-center rounded-md ring-1 ring-inset ring-slate-50 bg-white px-3 py-2 text-sm text-slate-700 shadow-sm hover:bg-slate-25 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
    @click="$emit('continue')"
  >
    <div
      class="w-10 h-10 rounded-md bg-slate-75 text-lg flex items-center justify-center flex-shrink-0"
    >
      💬
    </div>
    <div class="text-left flex flex-col justify-start flex-grow mx-2">
      <span class="font-semibold text-slate-900 text-brand-link">
        {{ title }}
      </span>
      <span>{{ content }}</span>
    </div>
    <div class="w-8 h-10 flex items-center justify-center">
      <fluent-icon icon="chevron-right" class="text-brand-link" />
    </div>
  </button>
</template>

<script>
export default {
  props: {
    title: {
      type: String,
      default: 'Continue your chat',
    },
    content: {
      type: String,
      default: 'Chat with us',
    },
  },
};
</script>
