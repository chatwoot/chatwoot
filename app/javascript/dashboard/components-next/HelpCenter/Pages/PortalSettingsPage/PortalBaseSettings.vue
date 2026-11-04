<script setup>
import { reactive, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { buildPortalURL } from 'dashboard/helper/portalHelper';
import { useStoreGetters } from 'dashboard/composables/store';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, helpers, url } from '@vuelidate/validators';
import { isValidSlug } from 'shared/helpers/Validators';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ColorPicker from 'dashboard/components-next/colorpicker/ColorPicker.vue';
import PortalLogoSettings from './PortalLogoSettings.vue';

const props = defineProps({
  activePortal: {
    type: Object,
    required: true,
  },
  isFetching: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['updatePortal']);

const { t } = useI18n();
const getters = useStoreGetters();

const state = reactive({
  name: '',
  headerText: '',
  pageTitle: '',
  slug: '',
  widgetColor: '',
  homePageLink: '',
  logos: {
    light: { url: '', blobId: '' },
    dark: { url: '', blobId: '' },
  },
});

const originalState = reactive({ ...state });

const rules = {
  name: { required, minLength: minLength(2) },
  slug: {
    required: helpers.withMessage(
      () => t('HELP_CENTER.CREATE_PORTAL_DIALOG.SLUG.ERROR'),
      required
    ),
    isValidSlug: helpers.withMessage(
      () => t('HELP_CENTER.CREATE_PORTAL_DIALOG.SLUG.FORMAT_ERROR'),
      isValidSlug
    ),
  },
  homePageLink: { url },
};

const v$ = useVuelidate(rules, state);

const nameError = computed(() =>
  v$.value.name.$error ? t('HELP_CENTER.CREATE_PORTAL_DIALOG.NAME.ERROR') : ''
);

const slugError = computed(() => {
  return v$.value.slug.$errors[0]?.$message || '';
});

const homePageLinkError = computed(() =>
  v$.value.homePageLink.$error
    ? t('HELP_CENTER.PORTAL_SETTINGS.FORM.HOME_PAGE_LINK.ERROR')
    : ''
);

const isUpdatingPortal = computed(() => {
  const slug = props.activePortal?.slug;
  if (slug) return getters['portals/uiFlagsIn'].value(slug)?.isUpdating;

  return false;
});

watch(
  () => props.activePortal,
  newVal => {
    if (newVal && !props.isFetching) {
      Object.assign(state, {
        name: newVal.name,
        headerText: newVal.header_text,
        pageTitle: newVal.page_title,
        widgetColor: newVal.color,
        homePageLink: newVal.homepage_link,
        slug: newVal.slug,
        logos: {
          light: { url: newVal.logo?.file_url || '', blobId: '' },
          dark: { url: newVal.dark_logo?.file_url || '', blobId: '' },
        },
      });
      Object.assign(originalState, state);
    }
  },
  { immediate: true, deep: true }
);

const hasChanges = computed(() => {
  return JSON.stringify(state) !== JSON.stringify(originalState);
});

const handleUpdatePortal = () => {
  const portal = {
    id: props.activePortal?.id,
    slug: state.slug,
    name: state.name,
    color: state.widgetColor,
    page_title: state.pageTitle,
    header_text: state.headerText,
    homepage_link: state.homePageLink,
    blob_id: state.logos.light.blobId,
    dark_logo_blob_id: state.logos.dark.blobId,
  };
  emit('updatePortal', portal);
};
</script>

<template>
  <div class="flex flex-col w-full gap-4">
    <PortalLogoSettings
      v-model="state.logos"
      :portal-slug="activePortal.slug"
      :portal-name="state.name"
    />
    <div class="flex flex-col w-full gap-4">
      <div
        class="grid items-start justify-between w-full gap-2 grid-cols-[200px,1fr]"
      >
        <label
          class="text-sm font-medium whitespace-nowrap py-2.5 text-n-slate-12"
        >
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.NAME.LABEL') }}
        </label>
        <Input
          v-model="state.name"
          :placeholder="t('HELP_CENTER.PORTAL_SETTINGS.FORM.NAME.PLACEHOLDER')"
          :message-type="nameError ? 'error' : 'info'"
          :message="nameError"
          custom-input-class="!bg-transparent dark:!bg-transparent"
          @input="v$.name.$touch()"
          @blur="v$.name.$touch()"
        />
      </div>
      <div
        class="grid items-start justify-between w-full gap-2 grid-cols-[200px,1fr]"
      >
        <label
          class="text-sm font-medium whitespace-nowrap py-2.5 text-n-slate-12"
        >
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.HEADER_TEXT.LABEL') }}
        </label>
        <Input
          v-model="state.headerText"
          :placeholder="
            t('HELP_CENTER.PORTAL_SETTINGS.FORM.HEADER_TEXT.PLACEHOLDER')
          "
          custom-input-class="!bg-transparent dark:!bg-transparent"
        />
      </div>
      <div
        class="grid items-start justify-between w-full gap-2 grid-cols-[200px,1fr]"
      >
        <label
          class="text-sm font-medium whitespace-nowrap text-n-slate-12 py-2.5"
        >
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.PAGE_TITLE.LABEL') }}
        </label>
        <Input
          v-model="state.pageTitle"
          :placeholder="
            t('HELP_CENTER.PORTAL_SETTINGS.FORM.PAGE_TITLE.PLACEHOLDER')
          "
          custom-input-class="!bg-transparent dark:!bg-transparent"
        />
      </div>
      <div
        class="grid items-start justify-between w-full gap-2 grid-cols-[200px,1fr]"
      >
        <label
          class="text-sm font-medium whitespace-nowrap text-n-slate-12 py-2.5"
        >
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.HOME_PAGE_LINK.LABEL') }}
        </label>
        <Input
          v-model="state.homePageLink"
          :placeholder="
            t('HELP_CENTER.PORTAL_SETTINGS.FORM.HOME_PAGE_LINK.PLACEHOLDER')
          "
          :message-type="homePageLinkError ? 'error' : 'info'"
          :message="homePageLinkError"
          custom-input-class="!bg-transparent dark:!bg-transparent"
          @input="v$.homePageLink.$touch()"
          @blur="v$.homePageLink.$touch()"
        />
      </div>
      <div
        class="grid items-start justify-between w-full gap-2 grid-cols-[200px,1fr]"
      >
        <label
          class="text-sm font-medium whitespace-nowrap py-2.5 text-n-slate-12"
        >
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.SLUG.LABEL') }}
        </label>
        <Input
          v-model="state.slug"
          :placeholder="t('HELP_CENTER.PORTAL_SETTINGS.FORM.SLUG.PLACEHOLDER')"
          :message-type="slugError ? 'error' : 'info'"
          :message="slugError || buildPortalURL(state.slug)"
          custom-input-class="!bg-transparent dark:!bg-transparent"
          @input="v$.slug.$touch()"
          @blur="v$.slug.$touch()"
        />
      </div>
      <div
        class="grid items-start justify-between w-full gap-2 grid-cols-[200px,1fr]"
      >
        <label
          class="text-sm font-medium whitespace-nowrap py-2.5 text-n-slate-12"
        >
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.BRAND_COLOR.LABEL') }}
        </label>
        <div class="w-[432px] justify-start">
          <ColorPicker v-model="state.widgetColor" />
        </div>
      </div>
      <div class="flex justify-end w-full gap-2">
        <Button
          :label="t('HELP_CENTER.PORTAL_SETTINGS.FORM.SAVE_CHANGES')"
          :disabled="!hasChanges || isUpdatingPortal || v$.$invalid"
          :is-loading="isUpdatingPortal"
          @click="handleUpdatePortal"
        />
      </div>
    </div>
  </div>
</template>
