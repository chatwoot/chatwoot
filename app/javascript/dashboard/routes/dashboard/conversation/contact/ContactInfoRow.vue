<template>
  <div class="contact-info--row">
    <a v-if="href" :href="href" class="contact-info--details">
      <emoji-or-icon :icon="icon" :emoji="emoji" />
      <span v-if="value" class="text-truncate" :title="value">{{ value }}</span>
      <span v-else class="text-muted">{{
        $t('CONTACT_PANEL.NOT_AVAILABLE')
      }}</span>

      <button
        v-if="showCopy"
        type="submit"
        class="button nice link hollow grey-btn compact"
        @click="onCopy"
      >
        <i class="icon copy-icon ion-clipboard"></i>
      </button>
    </a>

    <div v-else class="contact-info--details">
      <emoji-or-icon :icon="icon" :emoji="emoji" />
      <span v-if="value" class="text-truncate">{{ value }}</span>
      <span v-else class="text-muted">{{
        $t('CONTACT_PANEL.NOT_AVAILABLE')
      }}</span>
    </div>
  </div>
</template>
<script>
import copy from 'copy-text-to-clipboard';
import alertMixin from 'shared/mixins/alertMixin';
import EmojiOrIcon from 'shared/components/EmojiOrIcon';

export default {
  components: {
    EmojiOrIcon,
  },
  mixins: [alertMixin],
  props: {
    href: {
      type: String,
      default: '',
    },
    icon: {
      type: String,
      required: true,
    },
    emoji: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      default: '',
    },
    showCopy: {
      type: Boolean,
      default: false,
    },
  },
  methods: {
    onCopy(e) {
      e.preventDefault();
      copy(this.value);
      this.showAlert(this.$t('CONTACT_PANEL.COPY_SUCCESSFUL'));
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
  margin-bottom: var(--space-one);
  color: $color-body;

  .copy-icon {
    margin-left: $space-one;
    &:hover {
      color: $color-woot;
    }
  }

  &.a {
    &:hover {
      text-decoration: underline;
    }
  }
}

.contact-info--details .icon--emoji,
.contact-info--details .icon--font {
  margin-right: var(--space-small);
}
</style>
