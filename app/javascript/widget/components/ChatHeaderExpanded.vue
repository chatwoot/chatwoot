<template>
  <header
    class="header-expanded py-6 px-5 relative box-border w-full"
    :class="showBg ? 'bg-transparent' : 'bg-white dark:bg-slate-900'"
  >
    <div
      class="flex items-start"
      :class="[avatarUrl ? 'justify-between' : 'justify-end']"
    >
      <img
        v-if="avatarUrl"
        class="h-12 rounded-full"
        :src="avatarUrl"
        alt="Avatar"
      />
      <header-actions
        :show-popout-button="showPopoutButton"
        :show-end-conversation-button="false"
      />
    </div>
    <h2
      v-dompurify-html="introHeading"
      class="mt-4 text-2xl mb-2 font-normal"
      :class="$dm('text-slate-900', 'dark:text-slate-50')"
    />
    <p
      v-dompurify-html="introBody"
      class="text-base leading-normal"
      :class="$dm('text-slate-700', 'dark:text-slate-200')"
    />
  </header>
</template>

<script>
import HeaderActions from './HeaderActions';
import darkModeMixin from 'widget/mixins/darkModeMixin.js';

export default {
  name: 'ChatHeaderExpanded',
  components: {
    HeaderActions,
  },
  mixins: [darkModeMixin],
  props: {
    avatarUrl: {
      type: String,
      default: '',
    },
    introHeading: {
      type: String,
      default: '',
    },
    introBody: {
      type: String,
      default: '',
    },
    showPopoutButton: {
      type: Boolean,
      default: false,
    },
    showBg: {
      type: Boolean,
      default: true,
    },
  },
};
</script>
