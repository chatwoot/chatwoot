<template>
  <div
    v-if="showHead"
    class="message__mail-head"
    :class="{ 'is-incoming': isIncoming }"
  >
    <div v-if="toMails" class="meta-wrap">
      <strong>TO:</strong>
      <span>{{ toMails }}</span>
    </div>
    <div v-if="ccMails" class="meta-wrap">
      <strong>CC:</strong>
      <span>{{ ccMails }}</span>
    </div>
    <div v-if="bccMails" class="meta-wrap">
      <strong>BCC:</strong>
      <span>{{ bccMails }}</span>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    emailAttributes: {
      type: Array,
      default: () => ({}),
    },
    isIncoming: {
      type: Boolean,
      default: true,
    },
  },
  computed: {
    toMails() {
      const to = this.emailAttributes.to || [];
      return to.join(', ');
    },
    ccMails() {
      const cc = this.emailAttributes.cc || [];
      return cc.join(', ');
    },
    bccMails() {
      const bcc = this.emailAttributes.bcc || [];
      return bcc.join(', ');
    },
    showHead() {
      return this.toMails || this.ccMails || this.bccMails;
    },
  },
};
</script>
<style lang="scss" scoped>
.message__mail-head {
  padding-bottom: var(--space-small);
  margin-bottom: var(--space-small);
  border-bottom: 1px solid var(--w-300);

  &.is-incoming {
    border-bottom: 1px solid var(--color-border-light);
  }
}

.meta-wrap {
  strong {
    font-size: var(--font-size-micro);
  }
  span {
    font-size: var(--font-size-mini);
  }
}
</style>
