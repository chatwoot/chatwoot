<template>
  <div class="christmas-promo">
    <h2>Get 25% off on all Chatwoot plans</h2>
    <p class="promo-code">
      Use XMASCHATWOOT22
      <fluent-icon icon="copy" class="copy--icon" @click.native="onCopy" /> to
      avail the discount
    </p>
  </div>
</template>

<script>
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  mixins: [alertMixin],
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
  background-color: var(--r-400);
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
</style>
