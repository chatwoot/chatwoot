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
  computed: {
    unescapedIntroBody() {
      const txt = document.createElement('textarea');
      txt.innerHTML = this.introBody;
      const links = JSON.parse(txt.value);
      txt.innerHTML = "By using this feature, you accept our <b><a target='_blank' href='" + links.t + "'>Terms</a></b> and our <b><a target='_blank' href='" + links.p + "'>Privacy Policy</a></b>, that responses may be AI-generated, and that your conversation will be recorded for AI training.";
      return txt.value;
    },
  },
  setup() {
    const { getThemeClass } = useDarkMode();
    return { getThemeClass };
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
      :class="getThemeClass('text-slate-900', 'dark:text-slate-50')"
    />
    <p
      v-html="unescapedIntroBody"
      class="text-base leading-normal"
      :class="getThemeClass('text-slate-700', 'dark:text-slate-200')"
    />
  </header>
</template>
