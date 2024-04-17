<template>
  <div class="flex items-center w-full overflow-y-auto">
    <div
      class="flex flex-col h-full p-5 pt-16 mx-auto my-0 bg-white dark:bg-slate-900 font-inter"
    >
      <div class="flex flex-col gap-8 sm:max-w-3xl">
        <h2 class="text-2xl font-medium text-slate-900 dark:text-white">
          Profile Settings
        </h2>
        <user-basic-profile username="John Doe" size="72px" />
      </div>
    </div>
  </div>
</template>
<script setup>
import UserBasicProfile from './UserBasicProfile.vue';
</script>
