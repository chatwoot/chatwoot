<template>
  <div class="w-8 h-8">
    <router-link :to="dashboardPath" replace>
      <img :src="source" :alt="name" />
    </router-link>
  </div>
</template>
<script>
import { frontendURL } from 'dashboard/helper/URLHelper';

export default {
  props: {
    source: {
      type: String,
      default: '',
    },
    name: {
      type: String,
      default: '',
    },
    accountId: {
      type: Number,
      default: 0,
    },
  },
  computed: {
    dashboardPath() {
      return frontendURL(`accounts/${this.accountId}/dashboard`);
    },
  },
};
</script>
