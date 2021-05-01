<template>
  <div class="wrap">
    <div class="input-wrap">
      <textarea
        v-model="inputText"
        :placeholder="$t('NOTES.ADD.PLACEHOLDER')"
        class="input--note"
        @keydown.enter.shift.exact="onAdd"
      >
      </textarea>
    </div>
    <div class="footer">
      <woot-button
        size="tiny"
        color-scheme="warning"
        :title="$t('NOTES.ADD.TITLE')"
        :is-disabled="buttonDisabled"
        class="button-wrap"
        @click="onAdd"
      >
        {{ $t('NOTES.ADD.BUTTON') }}
      </woot-button>
    </div>
  </div>
</template>

<script>
import WootButton from 'dashboard/components/ui/WootButton.vue';
export default {
  components: {
    WootButton,
  },

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
.wrap {
  display: flex;
  flex-direction: column;
  border: 1px solid var(--color-border);
  border-radius: var(--border-radius-small);
  width: 100%;

  .input-wrap {
    display: flex;
    flex: 0 0 auto;
    width: 100%;

    .input--note {
      font-size: var(--font-size-mini);
      border-color: transparent;
      padding: var(--space-small) var(--space-small) 0 var(--space-small);
      resize: none;
      box-sizing: border-box;
      min-height: var(--space-larger);
      margin-bottom: var(--space-small);
    }
  }

  .footer {
    display: flex;
    justify-content: flex-end;
    flex: 1 1 auto;
    overflow: auto;
    width: 100%;

    .button-wrap {
      float: right;
      margin-bottom: var(--space-small);
      margin-right: var(--space-small);
    }
  }
}
</style>
