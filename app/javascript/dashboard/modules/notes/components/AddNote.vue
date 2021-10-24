<template>
  <div class="card">
    <woot-message-editor
      v-model="noteContent"
      class="input--note"
      :placeholder="$t('NOTES.ADD.PLACEHOLDER')"
      @keydown.enter.shift.exact="onAdd"
    />
    <div class="footer">
      <woot-button
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
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor';

export default {
  components: {
    WootMessageEditor,
  },

  data() {
    return {
      noteContent: '',
    };
  },

  computed: {
    buttonDisabled() {
      return this.noteContent === '';
    },
  },

  methods: {
    onAdd() {
      if (this.noteContent !== '') {
        this.$emit('add', this.noteContent);
      }
      this.noteContent = '';
    },
  },
};
</script>

<style lang="scss" scoped>
.input--note {
  &::v-deep .ProseMirror-menubar {
    padding: 0;
    margin-top: var(--space-minus-small);
  }
}

.footer {
  display: flex;
  justify-content: flex-end;
  width: 100%;
}
</style>
