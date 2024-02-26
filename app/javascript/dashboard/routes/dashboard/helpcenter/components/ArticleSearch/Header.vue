<template>
  <div class="flex flex-col py-1">
    <div class="flex align-middle align-justify py-2">
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
      <div class="absolute left-0 w-8 h-8 flex justify-center items-center">
        <fluent-icon icon="search" class="" size="16" />
      </div>
      <input
        ref="searchInput"
        type="text"
        :placeholder="$t('HELP_CENTER.ARTICLE_SEARCH.PLACEHOLDER')"
        class="block w-full pl-8 h-8 text-sm dark:bg-slate-700 bg-slate-25 rounded-md leading-8 py-1 text-slate-700 shadow-sm ring-2 ring-transparent ring-slate-300 border border-solid border-slate-300 placeholder:text-slate-400 focus:border-woot-600 focus:ring-woot-200 mb-0 focus:bg-slate-25 dark:focus:bg-slate-700 dark:focus:ring-woot-700"
        :value="searchQuery"
        @focus="onFocus"
        @blur="onBlur"
        @input="onInput"
      />
    </div>
  </div>
</template>

<script>
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import {
  buildHotKeys,
  isActiveElementTypeable,
} from 'shared/helpers/KeyboardHelpers';

export default {
  name: 'ChatwootSearch',
  mixins: [eventListenerMixins],
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
    handleKeyEvents(e) {
      const keyPattern = buildHotKeys(e);

      if (keyPattern === '/' && !isActiveElementTypeable(e)) {
        e.preventDefault();
        this.$refs.searchInput.focus();
      }
    },
  },
};
</script>
