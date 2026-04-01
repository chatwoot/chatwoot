<script>
export default {
  props: {
    headerTitle: { type: String, default: '' },
    headerContent: { type: String, default: '' },
  },
};
</script>

<template>
  <header class="mb-6 space-y-2">
    <h2
      class="mb-0 break-words text-2xl font-bold tracking-tight text-on-surface sm:text-3xl"
    >
      {{ headerTitle }}
    </h2>
    <p
      v-dompurify-html="headerContent"
      class="mb-0 max-w-2xl text-base leading-relaxed text-on-primary-container"
    />
  </header>
</template>
