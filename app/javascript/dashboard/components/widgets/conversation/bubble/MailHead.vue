<script>
export default {
  props: {
    emailAttributes: {
      type: Object,
      default: () => ({}),
    },
    isIncoming: {
      type: Boolean,
      default: true,
    },
    cc: {
      type: Array,
      default: () => [],
    },
    bcc: {
      type: Array,
      default: () => [],
    },
  },
  computed: {
    fromMail() {
      const from = this.emailAttributes.from || [];
      return from.join(', ');
    },
    toMails() {
      const to = this.emailAttributes.to || [];
      return to.join(', ');
    },
    ccMails() {
      const cc = this.emailAttributes.cc || this.cc || [];
      return cc.join(', ');
    },
    bccMails() {
      const bcc = this.emailAttributes.bcc || this.bcc || [];
      return bcc.join(', ');
    },
    subject() {
      return this.emailAttributes.subject || '';
    },
    showHead() {
      return this.toMails || this.ccMails || this.bccMails || this.fromMail;
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div
    v-if="showHead"
    class="message__mail-head"
    :class="{ 'is-incoming': isIncoming }"
  >
    <div v-if="fromMail" class="meta-wrap">
      <span class="message__content--type">{{ $t('EMAIL_HEADER.FROM') }}:</span>
      <span>{{ fromMail }}</span>
    </div>
    <div v-if="toMails" class="meta-wrap">
      <span class="message__content--type">{{ $t('EMAIL_HEADER.TO') }}:</span>
      <span>{{ toMails }}</span>
    </div>
    <div v-if="ccMails" class="meta-wrap">
      <span class="message__content--type">{{ $t('EMAIL_HEADER.CC') }}:</span>
      <span>{{ ccMails }}</span>
    </div>
    <div v-if="bccMails" class="meta-wrap">
      <span class="message__content--type">{{ $t('EMAIL_HEADER.BCC') }}:</span>
      <span>{{ bccMails }}</span>
    </div>
    <div v-if="subject" class="meta-wrap">
      <span class="message__content--type">
        {{ $t('EMAIL_HEADER.SUBJECT') }}:
      </span>
      <span>{{ subject }}</span>
    </div>
  </div>
</template>

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
  .message__content--type {
    font-weight: var(--font-weight-bold);
    font-size: var(--font-size-mini);
  }
  span {
    font-size: var(--font-size-mini);
  }
}
</style>
