<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';

import classicLayoutPreview from './classic-layout-preview.svg?raw';
import documentationLayoutPreview from './documentation-layout-preview.svg?raw';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';

const props = defineProps({
  activePortal: { type: Object, required: true },
  isFetching: { type: Boolean, default: false },
});

const emit = defineEmits(['updatePortalConfiguration']);

const { t } = useI18n();

const PORTAL_LAYOUTS = {
  CLASSIC: 'classic',
  DOCUMENTATION: 'documentation',
};

// `prefix` is the link the help center auto-fills; the DB only stores the handle.
const SOCIAL_PLATFORMS = [
  {
    key: 'facebook',
    label: 'Facebook',
    icon: 'i-ri-facebook-circle-fill',
    prefix: 'facebook.com/',
  },
  { key: 'x', label: 'X', icon: 'i-ri-twitter-x-fill', prefix: 'x.com/' },
  {
    key: 'instagram',
    label: 'Instagram',
    icon: 'i-ri-instagram-fill',
    prefix: 'instagram.com/',
  },
  {
    key: 'linkedin',
    label: 'LinkedIn',
    icon: 'i-ri-linkedin-box-fill',
    prefix: 'linkedin.com/',
  },
  {
    key: 'youtube',
    label: 'YouTube',
    icon: 'i-ri-youtube-fill',
    prefix: 'youtube.com/',
  },
  {
    key: 'tiktok',
    label: 'TikTok',
    icon: 'i-ri-tiktok-fill',
    prefix: 'tiktok.com/',
  },
  {
    key: 'github',
    label: 'GitHub',
    icon: 'i-ri-github-fill',
    prefix: 'github.com/',
  },
  {
    key: 'whatsapp',
    label: 'WhatsApp',
    icon: 'i-ri-whatsapp-fill',
    prefix: 'wa.me/',
  },
];

const portalConfig = computed(() => props.activePortal?.config || {});

const state = reactive({
  layout: PORTAL_LAYOUTS.CLASSIC,
  socialProfiles: {},
});
const visiblePlatforms = ref([]);
const showAddMenu = ref(false);

let originalSnapshot = '';

const platformByKey = key => SOCIAL_PLATFORMS.find(p => p.key === key);

const trimmedHandle = key => (state.socialProfiles[key] || '').trim();

const buildSocialProfiles = () =>
  visiblePlatforms.value.reduce((acc, key) => {
    const handle = trimmedHandle(key);
    if (handle) acc[key] = handle;
    return acc;
  }, {});

const snapshot = () =>
  JSON.stringify({ layout: state.layout, social: buildSocialProfiles() });

const resetFromPortal = () => {
  const savedProfiles = portalConfig.value.social_profiles || {};
  state.layout = portalConfig.value.layout || PORTAL_LAYOUTS.CLASSIC;
  state.socialProfiles = SOCIAL_PLATFORMS.reduce((acc, { key }) => {
    acc[key] = savedProfiles[key] || '';
    return acc;
  }, {});
  visiblePlatforms.value = SOCIAL_PLATFORMS.map(p => p.key).filter(key =>
    (savedProfiles[key] || '').trim()
  );
  originalSnapshot = snapshot();
};

watch(() => props.activePortal, resetFromPortal, {
  immediate: true,
  deep: true,
});

const hasChanges = computed(() => snapshot() !== originalSnapshot);

const visiblePlatformDetails = computed(() =>
  visiblePlatforms.value.map(platformByKey)
);

const addablePlatforms = computed(() =>
  SOCIAL_PLATFORMS.filter(p => !visiblePlatforms.value.includes(p.key)).map(
    p => ({ label: p.label, value: p.key, action: p.key, icon: p.icon })
  )
);

const addPlatform = ({ value }) => {
  if (!visiblePlatforms.value.includes(value)) {
    visiblePlatforms.value.push(value);
  }
  showAddMenu.value = false;
};

const removePlatform = key => {
  visiblePlatforms.value = visiblePlatforms.value.filter(k => k !== key);
  state.socialProfiles[key] = '';
};

const handleSave = () => {
  emit('updatePortalConfiguration', {
    id: props.activePortal.id,
    slug: props.activePortal.slug,
    config: {
      layout: state.layout,
      social_profiles: buildSocialProfiles(),
    },
  });
};
</script>

<template>
  <div class="flex flex-col w-full gap-6">
    <div class="flex flex-col gap-2">
      <h6 class="text-base font-medium text-n-slate-12">
        {{ t('HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.HEADER') }}
      </h6>
      <span class="text-sm text-n-slate-11">
        {{ t('HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.DESCRIPTION') }}
      </span>
    </div>

    <section class="flex flex-col gap-3">
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 text-n-slate-11">
        <RadioCard
          :id="PORTAL_LAYOUTS.CLASSIC"
          :is-active="state.layout === PORTAL_LAYOUTS.CLASSIC"
          :label="
            t('HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.LAYOUT.CLASSIC.TITLE')
          "
          :description="
            t(
              'HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.LAYOUT.CLASSIC.DESCRIPTION'
            )
          "
          @select="value => (state.layout = value)"
        >
          <div
            class="w-full mt-2 rounded-md overflow-hidden border border-solid border-n-weak bg-n-slate-2 dark:bg-n-slate-1"
          >
            <span v-dompurify-html="classicLayoutPreview" />
          </div>
        </RadioCard>

        <RadioCard
          :id="PORTAL_LAYOUTS.DOCUMENTATION"
          beta
          :is-active="state.layout === PORTAL_LAYOUTS.DOCUMENTATION"
          :label="
            t('HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.LAYOUT.SIDEBAR.TITLE')
          "
          :description="
            t(
              'HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.LAYOUT.SIDEBAR.DESCRIPTION'
            )
          "
          @select="value => (state.layout = value)"
        >
          <div
            class="w-full mt-2 rounded-md overflow-hidden border border-solid border-n-weak bg-n-slate-2 dark:bg-n-slate-1"
          >
            <span v-dompurify-html="documentationLayoutPreview" />
          </div>
        </RadioCard>
      </div>
    </section>

    <section
      v-if="state.layout === PORTAL_LAYOUTS.DOCUMENTATION"
      class="flex flex-col gap-3"
    >
      <div class="flex flex-col gap-1">
        <h6 class="text-sm font-medium text-n-slate-12">
          {{
            t('HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.SOCIAL_LINKS.HEADER')
          }}
        </h6>
        <span class="text-sm text-n-slate-11">
          {{
            t(
              'HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.SOCIAL_LINKS.DESCRIPTION'
            )
          }}
        </span>
      </div>

      <div
        v-for="platform in visiblePlatformDetails"
        :key="platform.key"
        class="flex items-center h-10 gap-1.5 px-3 rounded-lg outline outline-1 outline-n-weak focus-within:outline-n-brand"
      >
        <Icon :icon="platform.icon" class="size-4 shrink-0 text-n-slate-11" />
        <span class="text-sm shrink-0 text-n-slate-10">{{
          platform.prefix
        }}</span>
        <input
          v-model="state.socialProfiles[platform.key]"
          type="text"
          class="flex-1 min-w-0 text-sm bg-transparent outline-none reset-base text-n-slate-12 placeholder:text-n-slate-10"
          :placeholder="
            t(
              'HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.SOCIAL_LINKS.PLACEHOLDER'
            )
          "
        />
        <Button
          icon="i-lucide-x"
          color="slate"
          variant="ghost"
          size="xs"
          :aria-label="
            t('HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.SOCIAL_LINKS.REMOVE')
          "
          @click="removePlatform(platform.key)"
        />
      </div>

      <div
        v-if="addablePlatforms.length"
        v-on-clickaway="() => (showAddMenu = false)"
        class="relative"
      >
        <Button
          :label="
            t('HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.SOCIAL_LINKS.ADD')
          "
          icon="i-lucide-plus"
          color="slate"
          variant="faded"
          size="sm"
          @click="showAddMenu = !showAddMenu"
        />
        <DropdownMenu
          v-if="showAddMenu"
          :menu-items="addablePlatforms"
          class="mt-1 w-52 top-full ltr:left-0 rtl:right-0"
          @action="addPlatform"
        />
      </div>
    </section>

    <div class="flex justify-end">
      <Button
        :label="t('HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.SAVE')"
        :disabled="!hasChanges || isFetching"
        @click="handleSave"
      />
    </div>
  </div>
</template>
