<script setup>
import { toRef } from 'vue';
import { useRouter } from 'vue-router';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import HeaderActions from './HeaderActions.vue';
import AvailabilityContainer from 'widget/components/Availability/AvailabilityContainer.vue';
import { useAvailability } from 'widget/composables/useAvailability';
import { getReturnUrl, isStandaloneMode } from 'widget/helpers/urlParamsHelper';

const props = defineProps({
  avatarUrl: { type: String, default: '' },
  title: { type: String, default: '' },
  showPopoutButton: { type: Boolean, default: false },
  showBackButton: { type: Boolean, default: false },
  availableAgents: { type: Array, default: () => [] },
});

const availableAgents = toRef(props, 'availableAgents');

const router = useRouter();
const { isOnline } = useAvailability(availableAgents);
const isStandaloneChat = isStandaloneMode(window.location.search);

const toggleLocale = () => {
  const availableLocales = (window.chatwootWebChannel.enabledLanguages || [])
    .map(language => language.iso_639_1_code)
    .filter(Boolean);
  const currentLocale = window.WOOT_WIDGET?.$root?.$i18n?.locale;
  const nextLocale = availableLocales.find(locale => locale !== currentLocale);

  if (nextLocale && window.WOOT_WIDGET?.$root?.$i18n) {
    window.WOOT_WIDGET.$root.$i18n.locale = nextLocale;
  }
};

const onBackButtonClick = () => {
  const returnUrl = getReturnUrl(window.location.search);

  if (returnUrl) {
    if (window.parent && window.parent !== window) {
      window.parent.postMessage(
        `chatwoot-widget:${JSON.stringify({
          event: 'returnToUrl',
          returnUrl,
        })}`,
        '*'
      );
      return;
    }

    window.location.assign(returnUrl);
    return;
  }

  router.replace({ name: 'home' });
};
</script>

<template>
  <header
    class="flex justify-between w-full p-5 gap-2"
    :class="
      isStandaloneChat ? 'bg-[var(--widget-color,#2781f6)]' : 'bg-n-background'
    "
  >
    <div class="flex items-center">
      <button
        v-if="showBackButton"
        class="px-2 ltr:-ml-3 rtl:-mr-3"
        @click="onBackButtonClick"
      >
        <FluentIcon icon="chevron-left" size="24" class="text-n-slate-12" />
      </button>
      <img
        v-if="avatarUrl"
        class="w-8 h-8 ltr:mr-3 rtl:ml-3 rounded-full"
        :src="avatarUrl"
        alt="avatar"
      />
      <div class="flex flex-col gap-1">
        <div
          class="flex items-center text-base font-medium leading-4"
          :class="isStandaloneChat ? 'text-white' : 'text-n-slate-12'"
        >
          <span v-dompurify-html="title" class="ltr:mr-1 rtl:ml-1" />
          <div
            :class="`h-2 w-2 rounded-full
              ${isOnline ? 'bg-n-teal-10' : 'hidden'}`"
          />
        </div>
        <AvailabilityContainer
          :agents="availableAgents"
          :show-header="false"
          :show-avatars="false"
          text-classes="text-xs leading-3"
        />
      </div>
    </div>
    <div class="flex items-center gap-2">
      <button
        v-if="isStandaloneChat"
        class="flex items-center justify-center min-h-8 min-w-8 text-white"
        :aria-label="$t('LANGUAGE_SWITCHER')"
        @click="toggleLocale"
      >
        <FluentIcon icon="globe-outline" size="20" />
      </button>
      <HeaderActions :show-popout-button="showPopoutButton" />
    </div>
  </header>
</template>
