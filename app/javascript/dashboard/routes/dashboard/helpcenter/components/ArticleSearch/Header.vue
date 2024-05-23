<template>
  <div class="flex flex-col py-1">
    <div class="flex items-center justify-between py-2 mb-1">
      <h3 class="text-base text-slate-900 dark:text-slate-25">
        {{ title }}
      </h3>
      <woot-button
        variant="clear"
        size="tiny"
        color-scheme="secondary"
        icon="dismiss"
        @click="onClose"
      />
    </div>

    <div class="relative">
      <div
        class="absolute ltr:left-0 rtl:right-0 w-8 top-0.5 h-8 flex justify-center items-center"
      >
        <fluent-icon icon="search" class="" size="18" />
      </div>
      <input
        ref="searchInput"
        type="text"
        :placeholder="$t('HELP_CENTER.ARTICLE_SEARCH.PLACEHOLDER')"
        class="block w-full !h-9 ltr:!pl-8 rtl:!pr-8 dark:!bg-slate-700 !bg-slate-25 text-sm rounded-md leading-8 text-slate-700 shadow-sm ring-2 ring-transparent ring-slate-300 border border-solid border-slate-300 placeholder:text-slate-400 focus:border-woot-600 focus:ring-woot-200 !mb-0 focus:bg-slate-25 dark:focus:bg-slate-700 dark:focus:ring-woot-700"
        :value="searchQuery"
        @focus="onFocus"
        @blur="onBlur"
        @input="onInput"
      />
    </div>
  </div>
</template>

<script>
import keyboardEventListenerMixins from 'shared/mixins/keyboardEventListenerMixins';

export default {
  name: 'ChatwootSearch',
  mixins: [keyboardEventListenerMixins],
  props: {
    title: {
      type: String,
      default: 'Chatwoot',
    },
  },
  data() {
    return {
      searchQuery: '',
      isInputFocused: false,
    };
  },
  mounted() {
    this.$refs.searchInput.focus();
  },
  methods: {
    onInput(e) {
      this.$emit('search', e.target.value);
    },
    onClose() {
      this.$emit('close');
    },
    onFocus() {
      this.isInputFocused = true;
    },
    onBlur() {
      this.isInputFocused = false;
    },
    getKeyboardEvents() {
      return {
        Slash: {
          action: e => {
            e.preventDefault();
            this.$refs.searchInput.focus();
          },
        },
      };
    },
  },
};
</script>
