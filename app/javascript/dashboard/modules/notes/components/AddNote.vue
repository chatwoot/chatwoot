<script>
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import keyboardEventListenerMixins from 'shared/mixins/keyboardEventListenerMixins';
export default {
  components: {
    WootMessageEditor,
  },
  mixins: [keyboardEventListenerMixins],
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
    getKeyboardEvents() {
      return {
        '$mod+Enter': {
          action: () => this.onAdd(),
          allowOnFocusedInput: true,
        },
      };
    },
    onAdd() {
      if (this.noteContent !== '') {
        this.$emit('add', this.noteContent);
      }
      this.noteContent = '';
    },
  },
};
</script>

<template>
  <div
    class="flex flex-col flex-grow p-4 mb-2 overflow-hidden bg-white border border-solid rounded-md shadow-sm border-slate-75 dark:border-slate-700 dark:bg-slate-900 text-slate-700 dark:text-slate-100"
  >
    <WootMessageEditor
      v-model="noteContent"
      class="input--note"
      :placeholder="$t('NOTES.ADD.PLACEHOLDER')"
      :enable-suggestions="false"
    />
    <div class="flex justify-end w-full">
      <woot-button
        color-scheme="warning"
        :title="$t('NOTES.ADD.TITLE')"
        :is-disabled="buttonDisabled"
        @click="onAdd"
      >
        {{ $t('NOTES.ADD.BUTTON') }} {{ '(⌘⏎)' }}
      </woot-button>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.input--note {
  &::v-deep .ProseMirror-menubar {
    padding: 0;
    margin-top: var(--space-minus-small);
  }

  &::v-deep .ProseMirror-woot-style {
    max-height: 22.5rem;
  }
}
</style>
