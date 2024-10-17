<script setup>
import BaseCell from 'dashboard/components/table/BaseCell.vue';
defineProps({
  email: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <BaseCell>
    <a
      target="_blank"
      rel="noopener noreferrer nofollow"
      class="text-woot-500 dark:text-woot-500"
      :href="`mailto:${email}`"
    >
      {{ email }}
    </a>
  </BaseCell>
</template>
