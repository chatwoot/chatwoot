<script>
export default {
  props: {
    heading: {
      type: String,
      default: '',
    },
    content: {
      type: String,
      default: '',
    },
    active: {
      type: Boolean,
      default: false,
    },
    src: {
      type: String,
      default: '',
    },
  },
};
</script>

<template>
  <div
    class="flex flex-col min-w-[15rem] max-h-[21.25rem] max-w-[23.75rem] rounded-md border border-solid border-n-strong"
    :class="{
      'bg-woot-25 dark:bg-n-solid-2 border border-solid border-n-blue-border':
        active,
    }"
  >
    <div
      class="flex justify-between items-center rounded-t-md px-2 w-full h-10 bg-slate-50 dark:bg-slate-900 border-b border-solid border-n-strong"
      :class="{
        'bg-woot-50 border-b border-solid border-n-blue-border': active,
      }"
    >
      <div class="flex items-center p-1 text-sm font-medium">{{ heading }}</div>
      <fluent-icon
        v-if="active"
        icon="checkmark-circle"
        type="solid"
        size="24"
        class="text-woot-500 dark:text-woot-500"
      />
    </div>
    <div
      class="text-slate-700 dark:text-slate-200 text-xs leading-[1.4] px-3 pt-3 pb-0 text-start"
    >
      {{ content }}
    </div>
    <div v-if="src" class="p-3">
      <img
        :src="src"
        class="border border-solid rounded-md"
        :class="
          active
            ? 'border-woot-75 dark:border-woot-700'
            : 'border-slate-50 dark:border-slate-600'
        "
      />
    </div>
    <slot v-else />
  </div>
</template>
