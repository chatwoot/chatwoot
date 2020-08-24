<template>
  <div class="contact-info--row">
    <a v-if="href" :href="href" class="contact-info--details">
      <i :class="icon" class="contact-info--icon" />
      <span v-if="value" class="text-truncate">{{ value }}</span>
      <span v-else class="text-muted">{{
        $t('CONTACT_PANEL.NOT_AVAILABLE')
      }}</span>
    </a>
    <div v-else class="contact-info--details">
      <i :class="icon" class="contact-info--icon" />
      <span v-if="value" class="text-truncate">{{ value }}</span>
      <span v-else class="text-muted">{{
        $t('CONTACT_PANEL.NOT_AVAILABLE')
      }}</span>
    </div>
  </div>
</template>
<script>
export default {
  props: {
    href: {
      type: String,
      default: '',
    },
    icon: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      default: '',
    },
  },
};
</script>
<style scoped lang="scss">
@import '~dashboard/assets/scss/variables';

.contact-info--row {
  .contact-info--icon {
    font-size: $font-size-default;
    min-width: $space-medium;
  }
}

.contact-info--details {
  display: flex;
  align-items: center;
  margin-bottom: $space-smaller;
  color: $color-body;

  &.a {
    &:hover {
      text-decoration: underline;
    }
  }
}
</style>
