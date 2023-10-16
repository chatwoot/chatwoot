<template>
  <div class="flex items-center relative">
    <div
      v-if="icon"
      class="absolute cursor-pointer z-20 p-0.5 top-7 ltr:left-[38px] rtl:right-[38px] bg-red-100 hover:bg-red-200/50 dark:bg-red-800/30 dark:hover:bg-red-800/60 text-red-400 dark:text-red-500 hover:text-red-700 dark:hover:text-red-300 rounded-xl"
      @click="onClickInsertEmoji('')"
    >
      <fluent-icon size="12" icon="delete" type="outline" />
    </div>
    <div
      class="flex items-center justify-center absolute w-14 z-10 p-px bg-slate-75 hover:bg-slate-100 dark:bg-slate-800 dark:hover:bg-slate-700 cursor-pointer h-[2.33rem] ltr:rounded-l-[4px] rtl:rounded-r-[4px] top-[26px] ltr:left-px rtl:right-px"
      @click="toggleEmojiPicker"
    >
      <span v-if="icon" class="text-base ltr:mr-2 rtl:ml-2" v-html="icon" />
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
      class="w-full ltr:[&>input]:pl-16 rtl:[&>input]:pr-16 relative"
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
