<script>
import HeaderActions from './HeaderActions.vue';
import { useDarkMode } from 'widget/composables/useDarkMode';

export default {
  name: 'ChatHeaderExpanded',
  components: {
    HeaderActions,
  },
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
  },
  setup() {
    const { $dm } = useDarkMode();
    return { $dm };
  },
};
</script>

<template>
  <header
    class="header-expanded pt-6 pb-4 px-5 relative box-border w-full bg-transparent"
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
      <HeaderActions
        :show-popout-button="showPopoutButton"
        :show-end-conversation-button="false"
      />
    </div>
    <h2
      v-dompurify-html="introHeading"
      class="mt-4 text-2xl mb-1.5 font-medium"
      :class="$dm('text-slate-900', 'dark:text-slate-50')"
    />
    <p
      v-dompurify-html="introBody"
      class="text-base leading-normal"
      :class="$dm('text-slate-700', 'dark:text-slate-200')"
    />
  </header>
</template>
