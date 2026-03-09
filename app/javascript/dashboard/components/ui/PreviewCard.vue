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
    class="flex flex-col min-w-[15rem] max-h-[21.25rem] max-w-[23.75rem] rounded-md border border-solid"
    :class="{
      'bg-n-blue-1 dark:bg-n-solid-2 border-n-blue-4': active,
      'border-n-weak': !active,
    }"
  >
    <div
      class="flex justify-between items-center rounded-t-md px-2 w-full h-10 border-b border-solid"
      :class="{
        'bg-n-blue-2 border-n-blue-4': active,
        'bg-n-slate-2 border-n-weak': !active,
      }"
    >
      <div class="flex items-center p-1 text-sm font-medium">{{ heading }}</div>
      <fluent-icon
        v-if="active"
        icon="checkmark-circle"
        type="solid"
        size="24"
        class="text-n-brand"
      />
    </div>
    <div
      class="text-n-slate-11 text-xs leading-[1.4] px-3 pt-3 pb-0 text-start"
    >
      {{ content }}
    </div>
    <div v-if="src" class="p-3">
      <img
        :src="src"
        class="border rounded-md"
        :class="active ? 'border-n-blue-border' : 'border-n-weak'"
      />
    </div>
    <slot v-else />
  </div>
</template>
