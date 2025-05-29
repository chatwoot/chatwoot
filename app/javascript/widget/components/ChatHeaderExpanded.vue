<script setup>
import HeaderActions from './HeaderActions.vue';
import { computed } from 'vue';

const props = defineProps({
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
});

const containerClasses = computed(() => [
  props.avatarUrl ? 'justify-between' : 'justify-end',
]);

const unescapedIntroBody = computed(() => {
  const txt = document.createElement('textarea');
  txt.innerHTML = props.introBody;
  const links = JSON.parse(txt.value);
  txt.innerHTML = "By using this feature, you accept our <b><a target='_blank' href='" + links.t + "'>Terms</a></b> and our <b><a target='_blank' href='" + links.p + "'>Privacy Policy</a></b>, that responses may be AI-generated, and that your conversation will be recorded for AI training.";
  return txt.value;
});
</script>

<template>
  <header
    class="header-expanded pt-6 pb-4 px-5 relative box-border w-full bg-transparent"
  >
    <div class="flex items-start" :class="containerClasses">
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
      class="mt-4 text-2xl mb-1.5 font-medium text-n-slate-12"
    />
    <p
      v-html="unescapedIntroBody"
      class="text-lg leading-normal text-n-slate-11"
    />
  </header>
</template>
