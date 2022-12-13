<template>
  <router-link :to="navigateTo" class="contact-item">
    <thumbnail :src="contact.thumbnail" size="42px" :username="contact.name" />
    <div class="contact-details">
      <p class="name">{{ contact.name }}</p>
      <div class="details-meta">
        <p v-if="contact.email" class="email">{{ contact.email }}</p>
        <p v-if="contact.phone_number" class="separator">·</p>
        <p v-if="contact.phone_number" class="phone_number">
          {{ contact.phone_number }}
        </p>
      </div>
    </div>
  </router-link>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import { mapGetters } from 'vuex';
import { frontendURL } from 'dashboard/helper/URLHelper.js';
export default {
  components: {
    Thumbnail,
  },
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
    navigateTo() {
      return frontendURL(
        `accounts/${this.accountId}/contacts/${this.contact.id}`
      );
    },
  },
};
</script>

<style scoped lang="scss">
.contact-item {
  width: 100%;
  text-align: left;
  display: flex;
  cursor: pointer;
  align-items: center;
  padding: var(--space-small);

  .contact-details {
    margin-left: var(--space-slab);

    .name {
      margin: 0;
      color: var(--s-700);
      font-weight: var(--font-weight-bold);
      font-size: var(--font-size-default);
    }

    .details-meta {
      p {
        margin: 0;
        color: var(--s-500);
        font-size: var(--font-size-small);
      }
      display: flex;
      align-items: center;
    }
    .details-meta > :not([hidden]) ~ :not([hidden]) {
      margin-right: calc(1rem * 0);
      margin-left: calc(1rem * calc(1 - 0));
    }
  }
  &:hover {
    background-color: var(--s-50);
  }
}
</style>
