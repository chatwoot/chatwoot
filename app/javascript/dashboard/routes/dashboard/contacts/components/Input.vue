<template>
  <div class="wrap">
    <div class="input-wrap">
      <textarea
        v-model="inputText"
        :placeholder="$t('NOTES.ADD.PLACEHOLDER')"
        class="input-field"
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
  padding: var(--space-smaller);
  position: relative;
  border: 1px solid var(--color-border);
  border-radius: var(--border-radius-small);
  width: 100%;
  height: 10.8rem;
}

.input-wrap {
  display: flex;
  align-items: flex-end;
}

.input-field {
  width: 100%;
  height: 5.6rem;
  font-size: var(--font-size-mini);
  border-color: transparent;
  padding: var(--space-smaller);
  resize: none;
  box-sizing: border-box;
}

.button-wrap {
  position: absolute;
  right: var(--space-small);
  bottom: var(--space-small);
}
</style>
