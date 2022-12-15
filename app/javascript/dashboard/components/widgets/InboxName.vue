<template>
  <woot-button
    :title="$t('CONVERSATION.CARD.GOTO_INBOX')"
    class="inbox--icon"
    variant="link"
    size="tiny"
    color-scheme="secondary"
    :icon="computedInboxClass"
    class-names="inbox"
    @click="onClick"
  >
    {{ inbox.name }}
  </woot-button>
</template>
<script>
import { getInboxClassByType } from 'dashboard/helper/inbox';

export default {
  props: {
    inbox: {
      type: Object,
      default: () => {},
    },
  },
  computed: {
    computedInboxClass() {
      const { phone_number: phoneNumber, channel_type: type } = this.inbox;
      const classByType = getInboxClassByType(type, phoneNumber);
      return classByType;
    },
  },
  methods: {
    onClick(e) {
      e.stopPropagation();
      this.$router.push({
        name: 'inbox_dashboard',
        params: { inbox_id: this.inbox.id },
      });
    },
  },
};
</script>
<style lang="scss" scoped>
.inbox.button.clear.secondary {
  color: var(--s-600);
}
</style>
