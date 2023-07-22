<template>
  <header
    class="flex justify-between items-center w-full pb-4 border-b border-solid border-slate-50 px-4"
    :class="$dm('bg-white', 'dark:bg-slate-900')"
  >
    <div class="flex-grow flex items-center flex-shrink-0">
      <button
        v-if="showBackButton"
        class="inline-flex h-10 w-8 -ml-2 mr-1 rounded items-center justify-center text-slate-700 hover:bg-slate-25"
        @click="$emit('back')"
      >
        <fluent-icon icon="chevron-left" size="16" />
      </button>
      <img
        v-if="avatarUrl"
        class="h-8 w-8 rounded-full mr-3"
        :src="avatarUrl"
        alt="avatar"
      />
      <div
        v-else
        class="h-10 w-10 rounded-md bg-black-100 bg-brand-light inline-flex justify-center items-center mr-2 flex-shrink-0 font-bold"
      >
        🛟
      </div>
      <div>
        <h4
          class="font-semibold text-sm leading-4 flex items-center"
          :class="$dm('text-slate-900', 'dark:text-slate-50')"
        >
          <span v-dompurify-html="title" class="mr-1" />
          <div
            :class="
              `h-2 w-2 rounded-full
              ${isOnline ? 'bg-green-500' : 'hidden'}`
            "
          />
        </h4>
        <p
          class="text-xs mt-1 leading-3"
          :class="$dm('text-slate-700', 'dark:text-slate-400')"
        >
          {{ body }}
        </p>
      </div>
    </div>
    <header-actions
      v-if="showPopoutButton || showResolveButton"
      :show-popout-button="showPopoutButton"
      :show-resolve-button="showResolveButton"
      @popout="$emit('popout')"
      @resolve="$emit('resolve')"
    />
  </header>
</template>

<script>
import HeaderActions from './HeaderActions';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';

import darkMixin from 'widget/mixins/darkModeMixin.js';

export default {
  name: 'ChatHeader',
  components: {
    FluentIcon,
    HeaderActions,
  },
  mixins: [darkMixin],
  props: {
    avatarUrl: {
      type: String,
      default: '',
    },
    title: {
      type: String,
      default: '',
    },
    body: {
      type: String,
      default: '',
    },
    showPopoutButton: {
      type: Boolean,
      default: false,
    },
    showBackButton: {
      type: Boolean,
      default: false,
    },
    showResolveButton: {
      type: Boolean,
      default: false,
    },
    isOnline: {
      type: Boolean,
      default: false,
    },
  },
};
</script>
