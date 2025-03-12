<script>
export default {
  props: {
    headerTitle: {
      type: String,
      default: '',
    },
    headerContent: {
      type: String,
      default: '',
    },
  },
};
</script>

<template>
  <div class="pt-4 pb-0 px-8 border-b border-solid border-n-weak">
    <h2 class="text-2xl text-slate-800 dark:text-slate-100 mb-1 font-medium">
      {{ headerTitle }}
    </h2>
    <p
      v-if="headerContent"
      class="w-full text-slate-600 dark:text-slate-300 text-sm mb-2"
    >
      {{ headerContent }}
    </p>
    <slot />
  </div>
</template>
