<script setup>
defineProps({
  email: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <div
    class="overflow-hidden whitespace-nowrap text-ellipsis text-woot-500 dark:text-woot-500"
  >
    <a
      target="_blank"
      rel="noopener noreferrer nofollow"
      :href="`mailto:${email}`"
    >
      {{ email }}
    </a>
  </div>
</template>
