<script setup>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import { defineProps, computed } from 'vue';

const props = defineProps({
  users: {
    type: Array,
    default: () => [],
  },
  limit: {
    type: Number,
    default: 4,
  },
});

const usersToDisplay = computed(() => props.users.slice(0, props.limit));
</script>

<template>
  <div class="flex">
    <span
      v-for="(user, index) in usersToDisplay"
      :key="user.id"
      :class="index ? '-ml-4' : ''"
      class="inline-block rounded-full text-white shadow-solid"
    >
      <Thumbnail
        size="36px"
        :username="user.name"
        :src="user.avatar"
        has-border
      />
    </span>
  </div>
</template>
