<script setup>
import { reactive, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { buildPortalURL } from 'dashboard/helper/portalHelper';
import { useAlert } from 'dashboard/composables';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { useVuelidate } from '@vuelidate/core';
import {
  required,
  minLength,
  maxLength,
  helpers,
  url,
} from '@vuelidate/validators';
import { isValidSlug } from 'shared/helpers/Validators';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import ColorPicker from 'dashboard/components-next/colorpicker/ColorPicker.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

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
const store = useStore();
const getters = useStoreGetters();

const MAXIMUM_FILE_UPLOAD_SIZE = 4; // in MB
const CUSTOM_HTML_MAX_LENGTH = 15_000;

const state = reactive({
  name: '',
  headerText: '',
  pageTitle: '',
  slug: '',
  widgetColor: '',
  homePageLink: '',
  liveChatWidgetInboxId: '',
  logoUrl: '',
  avatarBlobId: '',
  showAuthor: true,
  customHeadHtml: '',
  customBodyHtml: '',
});

const originalState = reactive({ ...state });

const liveChatWidgets = computed(() => {
  const inboxes = store.getters['inboxes/getInboxes'];
  const widgetOptions = inboxes
    .filter(inbox => inbox.channel_type === 'Channel::WebWidget')
    .map(inbox => ({
      value: inbox.id,
      label: inbox.name,
    }));

  return [
    {
      value: '',
      label: t('HELP_CENTER.PORTAL_SETTINGS.FORM.LIVE_CHAT_WIDGET.NONE_OPTION'),
    },
    ...widgetOptions,
  ];
});

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
  customHeadHtml: { maxLength: maxLength(CUSTOM_HTML_MAX_LENGTH) },
  customBodyHtml: { maxLength: maxLength(CUSTOM_HTML_MAX_LENGTH) },
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

const customHeadHtmlError = computed(() =>
  v$.value.customHeadHtml.$error
    ? t('HELP_CENTER.PORTAL_SETTINGS.FORM.CUSTOM_HEAD_HTML.ERROR')
    : ''
);

const customBodyHtmlError = computed(() =>
  v$.value.customBodyHtml.$error
    ? t('HELP_CENTER.PORTAL_SETTINGS.FORM.CUSTOM_BODY_HTML.ERROR')
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
        liveChatWidgetInboxId: newVal.inbox?.id || '',
        showAuthor: newVal.config?.show_author !== false,
        customHeadHtml: newVal.custom_head_html || '',
        customBodyHtml: newVal.custom_body_html || '',
      });
      if (newVal.logo) {
        const {
          logo: { file_url: logoURL, blob_id: blobId },
        } = newVal;
        state.logoUrl = logoURL;
        state.avatarBlobId = blobId;
      } else {
        state.logoUrl = '';
        state.avatarBlobId = '';
      }
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
    blob_id: state.avatarBlobId,
    inbox_id: state.liveChatWidgetInboxId,
    config: { show_author: state.showAuthor },
    custom_head_html: state.customHeadHtml,
    custom_body_html: state.customBodyHtml,
  };
  emit('updatePortal', portal);
};

async function uploadLogoToStorage({ file }) {
  try {
    const { fileUrl, blobId } = await uploadFile(file);
    if (fileUrl) {
      state.logoUrl = fileUrl;
      state.avatarBlobId = blobId;
    }
    useAlert(t('HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.IMAGE_UPLOAD_SUCCESS'));
  } catch (error) {
    useAlert(t('HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.IMAGE_UPLOAD_ERROR'));
  }
}

async function deleteLogo() {
  try {
    const portalSlug = props.activePortal?.slug;
    await store.dispatch('portals/deleteLogo', {
      portalSlug,
    });
    useAlert(t('HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.IMAGE_DELETE_SUCCESS'));
  } catch (error) {
    useAlert(
      error?.message ||
        t('HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.IMAGE_DELETE_ERROR')
    );
  }
}

const handleAvatarUpload = file => {
  if (checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) {
    uploadLogoToStorage(file);
  } else {
    const errorKey =
      'HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.IMAGE_UPLOAD_SIZE_ERROR';
    useAlert(t(errorKey, { size: MAXIMUM_FILE_UPLOAD_SIZE }));
  }
};

const handleAvatarDelete = () => {
  state.logoUrl = '';
  state.avatarBlobId = '';
  deleteLogo();
};
</script>

<template>
  <div class="flex flex-col w-full gap-4">
    <div class="flex flex-col w-full gap-2">
      <label class="mb-0.5 text-sm font-medium text-gray-900 dark:text-gray-50">
        {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.LABEL') }}
      </label>
      <Avatar
        :src="state.logoUrl"
        :name="state.name"
        :size="72"
        allow-upload
        icon-name="i-lucide-building-2"
        @upload="handleAvatarUpload"
        @delete="handleAvatarDelete"
      />
    </div>
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
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.LIVE_CHAT_WIDGET.LABEL') }}
        </label>
        <ComboBox
          v-model="state.liveChatWidgetInboxId"
          :options="liveChatWidgets"
          :placeholder="
            t('HELP_CENTER.PORTAL_SETTINGS.FORM.LIVE_CHAT_WIDGET.PLACEHOLDER')
          "
          :message="
            t('HELP_CENTER.PORTAL_SETTINGS.FORM.LIVE_CHAT_WIDGET.HELP_TEXT')
          "
          class="[&>div>button:not(.focused)]:!outline-n-weak"
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
      <div
        class="grid items-start justify-between w-full gap-2 grid-cols-[200px,1fr]"
      >
        <label
          class="text-sm font-medium whitespace-nowrap py-2.5 text-n-slate-12"
        >
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.SHOW_AUTHOR.LABEL') }}
        </label>
        <div class="flex flex-col gap-1 py-2.5">
          <Switch v-model="state.showAuthor" />
          <span class="text-xs text-n-slate-11">
            {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.SHOW_AUTHOR.HELP_TEXT') }}
          </span>
        </div>
      </div>
      <div
        class="grid items-start justify-between w-full gap-2 grid-cols-[200px,1fr]"
      >
        <label
          class="text-sm font-medium whitespace-nowrap py-2.5 text-n-slate-12"
        >
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.CUSTOM_HEAD_HTML.LABEL') }}
        </label>
        <div class="flex flex-col gap-1">
          <textarea
            v-model="state.customHeadHtml"
            :placeholder="
              t('HELP_CENTER.PORTAL_SETTINGS.FORM.CUSTOM_HEAD_HTML.PLACEHOLDER')
            "
            rows="4"
            class="w-full px-3 py-2 text-sm border rounded-lg resize-y bg-transparent dark:bg-transparent text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-1 font-mono"
            :class="
              customHeadHtmlError
                ? 'border-n-ruby-9 focus:ring-n-ruby-9'
                : 'border-n-weak focus:ring-n-brand'
            "
            @input="v$.customHeadHtml.$touch()"
          />
          <span
            class="text-xs"
            :class="customHeadHtmlError ? 'text-n-ruby-9' : 'text-n-slate-11'"
          >
            {{
              customHeadHtmlError ||
              t('HELP_CENTER.PORTAL_SETTINGS.FORM.CUSTOM_HEAD_HTML.HELP_TEXT')
            }}
          </span>
        </div>
      </div>
      <div
        class="grid items-start justify-between w-full gap-2 grid-cols-[200px,1fr]"
      >
        <label
          class="text-sm font-medium whitespace-nowrap py-2.5 text-n-slate-12"
        >
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.CUSTOM_BODY_HTML.LABEL') }}
        </label>
        <div class="flex flex-col gap-1">
          <textarea
            v-model="state.customBodyHtml"
            :placeholder="
              t('HELP_CENTER.PORTAL_SETTINGS.FORM.CUSTOM_BODY_HTML.PLACEHOLDER')
            "
            rows="4"
            class="w-full px-3 py-2 text-sm border rounded-lg resize-y bg-transparent dark:bg-transparent text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-1 font-mono"
            :class="
              customBodyHtmlError
                ? 'border-n-ruby-9 focus:ring-n-ruby-9'
                : 'border-n-weak focus:ring-n-brand'
            "
            @input="v$.customBodyHtml.$touch()"
          />
          <span
            class="text-xs"
            :class="customBodyHtmlError ? 'text-n-ruby-9' : 'text-n-slate-11'"
          >
            {{
              customBodyHtmlError ||
              t('HELP_CENTER.PORTAL_SETTINGS.FORM.CUSTOM_BODY_HTML.HELP_TEXT')
            }}
          </span>
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
