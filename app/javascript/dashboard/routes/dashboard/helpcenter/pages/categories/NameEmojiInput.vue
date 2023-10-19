<template>
  <div class="flex items-center relative">
    <div
      class="flex items-center justify-center absolute z-10 hover:bg-slate-50 dark:bg-slate-900 dark:hover:bg-slate-700 cursor-pointer h-[2.4375rem] w-[2.4375rem] rounded-[4px] top-[25px] border border-solid border-slate-200 dark:border-slate-600"
      @click="toggleEmojiPicker"
    >
      <span v-if="icon" v-dompurify-html="icon" class="text-lg" />
      <fluent-icon
        v-else
        size="18"
        icon="emoji-add"
        type="outline"
        class="text-slate-400 dark:text-slate-600"
      />
    </div>
    <woot-input
      v-model="name"
      :class="{ error: hasError }"
      class="!mt-0 !mb-4 !mx-0 [&>input]:!mb-0 ltr:[&>input]:ml-12 rtl:[&>input]:mr-12 relative w-[calc(100%-3rem)] [&>p]:w-max"
      :error="nameErrorMessage"
      :label="label"
      :placeholder="placeholder"
      :help-text="helpText"
      @input="onNameChange"
    />
    <emoji-input
      v-if="showEmojiPicker"
      v-on-clickaway="hideEmojiPicker"
      class="left-0 top-16"
      :show-remove-button="true"
      :on-click="onClickInsertEmoji"
    />
  </div>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';

const EmojiInput = () => import('shared/components/emoji/EmojiInput');

export default {
  components: { EmojiInput },
  mixins: [clickaway],
  props: {
    label: {
      type: String,
      default: '',
    },
    placeholder: {
      type: String,
      default: '',
    },
    helpText: {
      type: String,
      default: '',
    },
    hasError: {
      type: Boolean,
      default: false,
    },
    errorMessage: {
      type: String,
      default: '',
    },
    existingName: {
      type: String,
      default: '',
    },
    savedIcon: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      name: '',
      icon: '',
      showEmojiPicker: false,
    };
  },
  computed: {
    nameErrorMessage() {
      if (this.hasError) {
        return this.errorMessage;
      }
      return '';
    },
  },
  mounted() {
    this.updateDataFromStore();
  },
  methods: {
    updateDataFromStore() {
      this.name = this.existingName;
      this.icon = this.savedIcon;
    },
    toggleEmojiPicker() {
      this.showEmojiPicker = !this.showEmojiPicker;
    },
    onClickInsertEmoji(emoji = '') {
      this.icon = emoji;
      this.$emit('icon-change', emoji);
      this.showEmojiPicker = false;
    },
    onNameChange() {
      this.$emit('name-change', this.name);
    },
    hideEmojiPicker() {
      if (this.showEmojiPicker) {
        this.showEmojiPicker = false;
      }
    },
  },
};
</script>

<style scoped lang="scss">
.emoji-dialog::before {
  @apply hidden;
}
</style>
