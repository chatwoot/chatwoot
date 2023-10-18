<template>
  <div
    class="flex items-center relative"
    @mouseover="showRemoveEmojiButton = true"
    @mouseleave="showRemoveEmojiButton = false"
  >
    <div
      v-if="icon && showRemoveEmojiButton"
      class="absolute cursor-pointer z-20 top-4 ltr:left-11 rtl:right-11 rounded-xl"
      @click="onClickInsertEmoji('')"
    >
      <fluent-icon
        size="18"
        icon="dismiss-circle"
        type="outline"
        class="text-red-400 dark:text-red-500 hover:text-red-700 dark:hover:text-red-300"
      />
    </div>
    <div
      class="flex items-center justify-center absolute w-14 z-10 hover:bg-slate-50 dark:hover:bg-slate-700 cursor-pointer h-[2.4375rem] rounded-[4px] top-[25px] border border-solid border-slate-200 dark:border-slate-800"
      @click="toggleEmojiPicker"
    >
      <span v-if="icon" v-dompurify-html="icon" class="text-lg" />
      <fluent-icon
        v-else
        size="18"
        icon="emoji"
        type="outline"
        class="text-slate-800 dark:text-slate-100"
      />
    </div>
    <woot-input
      v-model.trim="name"
      :class="{ error: hasError }"
      class="ltr:[&>input]:ml-16 rtl:[&>input]:mr-16 relative w-[calc(100%-4rem)] [&>p]:w-max"
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
      showRemoveEmojiButton: false,
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
.input-container::v-deep {
  @apply mt-0 mb-4 mx-0;

  input {
    @apply mb-0;
  }
}
.emoji-dialog::before {
  @apply hidden;
}
</style>
