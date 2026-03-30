<script setup>
import { ref, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { LocalStorage } from 'shared/helpers/localStorage';
import MessageFormatter from 'shared/helpers/MessageFormatter';
import NextButton from 'dashboard/components-next/button/Button.vue';

const BANNER_COLOR_CLASSES = {
  info: 'bg-n-brand text-white dark:text-white [&_.link]:text-white',
  warning: 'bg-n-amber-5 text-n-amber-12 [&_.link]:text-n-amber-12',
  error: 'bg-n-ruby-3 text-n-ruby-12 [&_.link]:text-n-ruby-12',
};

const BUTTON_COLOR_MAP = {
  info: 'blue',
  warning: 'amber',
  error: 'ruby',
};

const { t } = useI18n();
const globalConfig = useMapGetter('globalConfig/get');

const dismissedBannerIds = ref(
  LocalStorage.get(LOCAL_STORAGE_KEYS.DISMISSED_PLATFORM_BANNERS) || []
);

const visibleBanners = computed(() => {
  const banners = globalConfig.value?.activePlatformBanners || [];
  return banners.filter(
    banner => !dismissedBannerIds.value.includes(banner.id)
  );
});

const bannerClasses = bannerType =>
  BANNER_COLOR_CLASSES[bannerType] || BANNER_COLOR_CLASSES.warning;

const formattedMessage = message =>
  new MessageFormatter(message).formattedMessage;

const buttonColor = bannerType => BUTTON_COLOR_MAP[bannerType] || 'amber';

const dismissBanner = bannerId => {
  dismissedBannerIds.value.push(bannerId);
  LocalStorage.set(
    LOCAL_STORAGE_KEYS.DISMISSED_PLATFORM_BANNERS,
    dismissedBannerIds.value
  );
};
</script>

<template>
  <div
    v-for="banner in visibleBanners"
    :key="banner.id"
    class="flex items-center justify-center min-h-12 gap-4 px-4 py-3 text-xs [&_.link]:underline [&_.link]:ml-1 [&_.link]:text-xs [&_p]:m-0"
    :class="bannerClasses(banner.banner_type)"
  >
    <span
      v-dompurify-html="formattedMessage(banner.banner_message)"
      class="flex items-center overflow-hidden text-ellipsis"
    />
    <div class="flex gap-1 flex-shrink-0">
      <NextButton
        xs
        icon="i-lucide-circle-x"
        :color="buttonColor(banner.banner_type)"
        :label="t('GENERAL_SETTINGS.DISMISS')"
        @click="dismissBanner(banner.id)"
      />
    </div>
  </div>
</template>
