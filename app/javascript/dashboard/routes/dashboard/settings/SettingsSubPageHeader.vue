<template>
  <div class="flex flex-col w-full items-start">
    <h2
      class="text-xl font-medium mb-1 text-slate-800 dark:text-slate-100 break-words"
    >
      {{ headerTitle }}
    </h2>
    <p
      v-dompurify-html="headerContent"
      class="text-sm w-full text-slate-600 dark:text-slate-300"
    />
  </div>
</template>

<script>
export default {
  props: {
    headerTitle: { type: String, default: '' },
    headerContent: { type: String, default: '' },
  },
};
</script>
