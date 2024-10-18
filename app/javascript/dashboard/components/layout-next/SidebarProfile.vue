<script setup>
import { useMapGetter } from 'dashboard/composables/store';
import Avatar from 'dashboard/components/base-next/avatar/Avatar.vue';
const currentUser = useMapGetter('getCurrentUser');
</script>

<template>
  <div class="flex gap-2 items-center rounded-lg cursor-pointer">
    <Avatar
      :size="32"
      :name="currentUser.available_name"
      :src="currentUser.avatar_url"
    />
    <div>
      <div class="text-n-slate-12 text-sm leading-4 font-medium">
        {{ currentUser.available_name }}
      </div>
      <div class="text-n-slate-11 text-xs">
        {{ currentUser.email }}
      </div>
    </div>
  </div>
</template>
