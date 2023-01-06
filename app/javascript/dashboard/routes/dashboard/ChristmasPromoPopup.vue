<template>
  <div class="christmas-promo">
    <h2>Get 25% off on all Chatwoot plans</h2>
    <p class="promo-code">
      Use the code: XMASCHATWOOT22
      <fluent-icon icon="copy" class="copy--icon" @click.native="onCopy" />
      during checkout.
    </p>
    <router-link
      :to="addAccountScoping('settings/billing')"
      class="link"
      @click.native="$emit('close')"
    >
      Go to the billing page
    </router-link>
  </div>
</template>

<script>
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import alertMixin from 'shared/mixins/alertMixin';
import accountMixin from 'dashboard/mixins/account.js';

export default {
  mixins: [alertMixin, accountMixin],
  methods: {
    async onCopy(e) {
      e.preventDefault();
      await copyTextToClipboard('XMASCHATWOOT22');
      this.showAlert('Copied to clipboard');
    },
  },
};
</script>

<style scoped lang="scss">
.christmas-promo {
  height: var(--space-giga);
  background-image: url('/dashboard/images/christmas-promo.webp');
  background-position: center;
  background-size: cover;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;

  h2 {
    color: var(--white);
    font-size: var(--font-size-big);
    font-weight: var(--font-weight-bold);
  }

  .promo-code {
    color: var(--white);
    margin-top: var(--space-slab);
    svg {
      display: inline-block;
      vertical-align: middle;
      cursor: pointer;
    }
  }
}

.link {
  background-color: var(--white);
  padding: var(--space-slab) var(--space-normal);
  border-radius: var(--border-radius-normal);
  display: inline-block;
  margin-top: var(--space-slab);
  text-decoration: none;
}
</style>
