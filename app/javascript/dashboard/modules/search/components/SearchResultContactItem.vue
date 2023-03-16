<template>
  <router-link :to="navigateTo" class="contact-item">
    <woot-thumbnail :src="thumbnail" :username="name" size="24px" />
    <div class="contact-details">
      <h5 class="text-block-title name">{{ name }}</h5>
      <p class="details-meta">
        <span v-if="email" class="email">{{ email }}</span>
        <span v-if="phone" class="separator">•</span>
        <span v-if="phone" class="phone">
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
  cursor: pointer;
  display: flex;
  align-items: center;
  padding: var(--space-small);
  border-radius: var(--border-radius-small);

  &:hover {
    background-color: var(--s-25);
  }
}
.contact-details {
  margin-left: var(--space-small);
}
.name {
  margin: 0;
}
.details-meta {
  margin: 0;
  color: var(--s-600);
  font-size: var(--font-size-small);
  display: flex;
  align-items: center;

  span {
    margin-right: var(--space-smaller);
  }
}
</style>
