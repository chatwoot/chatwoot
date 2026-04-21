<script setup>
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
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
      :class="index ? 'ltr:-ml-4 rtl:-mr-4' : ''"
      class="inline-block rounded-full text-white shadow-solid"
    >
      <Avatar
        :name="user.name"
        :src="user.avatar_url"
        :size="36"
        class="[&>span]:outline [&>span]:outline-1 [&>span]:outline-n-background"
        rounded-full
      />
    </span>
  </div>
</template>
