<script>
import { debounce } from '@chatwoot/utils';
export default {
  props: {
    placeholder: {
      type: String,
      default: '',
    },
  },
  emits: ['search'],
  data() {
    return {
      searchQuery: '',
    };
  },
  methods: {
    handleInput: debounce(
      () => {
        this.$emit('search', this.searchQuery);
      },
      500,
      true
    ),
  },
};
</script>

<template>
  <div class="relative flex items-center">
    <div
      class="absolute inset-y-0 left-0 flex items-center h-8 px-2 text-slate-500"
    >
      <fluent-icon icon="search" size="14" />
    </div>
    <input
      id="search"
      v-model="searchQuery"
      :placeholder="placeholder"
      type="text"
      name="search"
      class="block w-full h-8 px-2 pl-6 pr-1 m-0 text-sm border rounded-md focus-visible:outline-none text-slate-800 border-slate-100 bg-slate-75 placeholder:text-slate-400 focus:ring focus:border-woot-500 focus:ring-woot-200 hover:border-woot-200"
      @input="handleInput"
    />
    <div class="absolute inset-y-0 right-0 flex h-8 p-1">
      <kbd
        class="inline-flex items-center px-1 font-sans border rounded border-slate-200 text-xxs text-slate-400"
      >
        {{ '⌘K' }}
      </kbd>
    </div>
  </div>
</template>
