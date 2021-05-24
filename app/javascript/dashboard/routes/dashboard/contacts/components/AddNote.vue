<template>
  <div class="card">
    <textarea
      v-model="inputText"
      :placeholder="$t('NOTES.ADD.PLACEHOLDER')"
      class="input--note"
      @keydown.enter.shift.exact="onAdd"
    />
    <div class="footer">
      <woot-button
        size="tiny"
        color-scheme="warning"
        :title="$t('NOTES.ADD.TITLE')"
        :is-disabled="buttonDisabled"
        @click="onAdd"
      >
        {{ $t('NOTES.ADD.BUTTON') }}
      </woot-button>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      inputText: '',
    };
  },

  computed: {
    buttonDisabled() {
      return this.inputText === '';
    },
  },

  methods: {
    onAdd() {
      if (this.inputText !== '') {
        this.$emit('add', this.inputText);
      }
      this.inputText = '';
    },
  },
};
</script>

<style lang="scss" scoped>
.input--note {
  font-size: var(--font-size-mini);
  border-color: transparent;
  margin-bottom: var(--space-small);
  padding: 0;
  resize: none;
  min-height: var(--space-larger);
}

.footer {
  display: flex;
  justify-content: flex-end;
  width: 100%;
}
</style>
