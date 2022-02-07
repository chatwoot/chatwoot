<template>
  <div class="logo">
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
<style lang="scss" scoped>
$logo-size: 32px;

.logo {
  padding: var(--space-normal);

  img {
    width: $logo-size;
    height: $logo-size;
    object-fit: cover;
    object-position: left center;
  }
}
</style>
