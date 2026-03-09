<script setup>
import { computed } from 'vue';
import { frontendURL } from 'dashboard/helper/URLHelper';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  id: {
    type: [String, Number],
    default: 0,
  },
  email: {
    type: String,
    default: '',
  },
  phone: {
    type: String,
    default: '',
  },
  name: {
    type: String,
    default: '',
  },
  thumbnail: {
    type: String,
    default: '',
  },
  accountId: {
    type: [String, Number],
    default: 0,
  },
});

const navigateTo = computed(() => {
  return frontendURL(`accounts/${props.accountId}/contacts/${props.id}`);
});
</script>

<template>
  <router-link
    :to="navigateTo"
    class="flex items-start p-2 rounded-xl cursor-pointer hover:bg-n-slate-2"
  >
    <Avatar
      :name="name"
      :src="thumbnail"
      :size="24"
      rounded-full
      class="mt-0.5"
    />
    <div class="ml-2 rtl:mr-2 min-w-0 rtl:ml-0">
      <h5 class="text-sm name truncate min-w-0 text-n-slate-12">
        {{ name }}
      </h5>
      <p
        class="grid items-center m-0 gap-1 text-sm grid-cols-[minmax(0,1fr)_auto_auto]"
      >
        <span v-if="email" class="truncate text-n-slate-12" :title="email">
          {{ email }}
        </span>
        <span v-if="phone" class="text-n-slate-10">•</span>
        <span v-if="phone" class="text-n-slate-12">{{ phone }}</span>
      </p>
    </div>
  </router-link>
</template>
