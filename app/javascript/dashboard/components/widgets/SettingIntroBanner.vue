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
  <div class="border-b border-solid border-s-border/60">
    <div class="max-w-7xl w-full mx-auto pt-4 pb-0 px-6">
      <h2 class="text-2xl text-s-primary mb-1 font-medium">
        {{ headerTitle }}
      </h2>
      <p v-if="headerContent" class="w-full text-s-muted text-sm mb-2">
        {{ headerContent }}
      </p>
      <slot />
    </div>
  </div>
</template>
