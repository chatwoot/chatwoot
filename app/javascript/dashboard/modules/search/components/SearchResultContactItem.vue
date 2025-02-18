<script setup>
import { frontendURL } from 'dashboard/helper/URLHelper';
import { computed } from 'vue';

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
    class="flex items-center p-2 rounded-md cursor-pointer hover:bg-n-slate-3 dark:hover:bg-n-solid-3"
  >
    <woot-thumbnail :src="thumbnail" :username="name" size="24px" />
    <div class="ml-2 rtl:mr-2 rtl:ml-0">
      <h5 class="text-sm name text-n-slate-12 dark:text-n-slate-12">
        {{ name }}
      </h5>
      <p
        class="flex items-center gap-1 m-0 text-sm text-slate-600 dark:text-slate-200"
      >
        <span v-if="email" class="email text-n-slate-12 dark:text-n-slate-12">{{
          email
        }}</span>
        <span
          v-if="phone"
          class="separator text-n-slate-10 dark:text-n-slate-10"
        >
          •
        </span>
        <span v-if="phone" class="phone text-n-slate-12 dark:text-n-slate-12">
          {{ phone }}
        </span>
      </p>
    </div>
  </router-link>
</template>
