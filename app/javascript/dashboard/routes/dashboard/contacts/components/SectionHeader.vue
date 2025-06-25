<template>
  <div class="wrap">
    <div class="header">
      <h5 class="block-title">
        {{ $t('EVENTS.HEADER.TITLE') }}
      </h5>
    </div>
    <div class="button-wrap">
      <woot-button
        variant="hollow"
        size="tiny"
        color-scheme="secondary"
        class-names="pill-button"
        @click="onClickNotes"
      >
        {{ $t('EVENTS.BUTTON.PILL_BUTTON_NOTES') }}
      </woot-button>
      <woot-button
        variant="hollow"
        size="tiny"
        color-scheme="secondary"
        class-names="pill-button"
        @click="onClickEvents"
      >
        {{ $t('EVENTS.BUTTON.PILL_BUTTON_EVENTS') }}
      </woot-button>
      <woot-button
        variant="hollow"
        size="tiny"
        color-scheme="secondary"
        class-names="pill-button"
        @click="onClickConversation"
      >
        {{ $t('EVENTS.BUTTON.PILL_BUTTON_CONVO') }}
      </woot-button>
    </div>
  </div>
</template>

<script>
export default {
  methods: {
    onClickNotes() {
      this.$emit('notes');
    },

    onClickEvents() {
      this.$emit('events');
    },

    onClickConversation() {
      this.$emit('conversation');
    },
  },
};
</script>

<style lang="scss" scoped>
.wrap {
  width: 100%;
  padding: var(--space-normal);

  .button-wrap {
    display: flex;

    .pill-button {
      margin-right: var(--space-small);
    }
  }
}
</style>
