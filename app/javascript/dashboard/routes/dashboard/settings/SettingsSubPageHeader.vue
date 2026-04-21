<script>
export default {
  props: {
    headerTitle: { type: String, default: '' },
    headerContent: { type: String, default: '' },
  },
};
</script>

<template>
  <div class="flex flex-col gap-1.5 w-full items-start mb-4">
    <h2 class="text-heading-1 text-s-primary break-words">
      {{ headerTitle }}
    </h2>
    <p
      v-dompurify-html="headerContent"
      class="text-body-main w-full text-s-muted"
    />
  </div>
</template>
