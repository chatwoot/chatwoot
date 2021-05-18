<template>
  <div class="wrap">
    <div class="header">
      <h5 class="block-title">
        Activities
      </h5>
    </div>
    <div class="button-wrap">
      <woot-button
        variant="hollow"
        size="tiny"
        color-scheme="secondary"
        class-names="buttons"
        label="notes"
        @click="onClickNotes"
      >
        notes
      </woot-button>
      <woot-button
        variant="hollow"
        size="tiny"
        color-scheme="secondary"
        class-names="buttons"
        label="events"
        @click="onClickEvents"
      >
        events
      </woot-button>
      <woot-button
        variant="hollow"
        size="tiny"
        color-scheme="secondary"
        class-names="buttons"
        label="conversations"
        @click="onClickConversation"
      >
        conversations
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
  padding: var(--space-small);

  .button-wrap {
    display: flex;

    .buttons {
      margin-right: var(--space-one);
    }
  }
}
</style>
