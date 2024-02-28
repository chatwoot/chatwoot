<template>
  <router-link :to="navigateTo" class="contact-item">
    <woot-thumbnail :src="thumbnail" :username="name" size="24px" />
    <div class="ml-2 rtl:mr-2 rtl:ml-0">
      <h5 class="text-sm name text-slate-800 dark:text-slate-200">
        {{ name }}
      </h5>
      <p
        class="m-0 text-slate-600 dark:text-slate-200 gap-1 text-sm flex items-center"
      >
        <span v-if="email" class="email text-slate-800 dark:text-slate-200">{{
          email
        }}</span>
        <span v-if="phone" class="separator text-slate-700 dark:text-slate-200">
          •
        </span>
        <span v-if="phone" class="phone text-slate-800 dark:text-slate-200">
          {{ phone }}
        </span>
      </p>
    </div>
  </router-link>
</template>

<script>
import { frontendURL } from 'dashboard/helper/URLHelper';
export default {
  props: {
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
  },
  computed: {
    navigateTo() {
      return frontendURL(`accounts/${this.accountId}/contacts/${this.id}`);
    },
  },
};
</script>

<style scoped lang="scss">
.contact-item {
  @apply cursor-pointer flex items-center p-2 rounded-sm hover:bg-slate-25 dark:hover:bg-slate-800;
}
.contact-details {
  @apply ml-2 rtl:mr-2 rtl:ml-0;
}
</style>
