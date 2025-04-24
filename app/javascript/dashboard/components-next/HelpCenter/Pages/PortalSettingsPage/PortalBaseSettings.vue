<script setup>
import { reactive, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { buildPortalURL } from 'dashboard/helper/portalHelper';
import { useAlert } from 'dashboard/composables';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, helpers } from '@vuelidate/validators';
import { shouldBeUrl, isValidSlug } from 'shared/helpers/Validators';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import ColorPicker from 'dashboard/components-next/colorpicker/ColorPicker.vue';

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
});

const originalState = reactive({ ...state });

const liveChatWidgets = computed(() => {
  const inboxes = store.getters['inboxes/getInboxes'];
  return inboxes
    .filter(inbox => inbox.channel_type === 'Channel::WebWidget')
    .map(inbox => ({
      value: inbox.id,
      label: inbox.name,
    }));
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
  homePageLink: { shouldBeUrl },
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
        liveChatWidgetInboxId: newVal.inbox?.id,
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
          class="text-sm font-medium whitespace-nowrap py-2.5 text-slate-900 dark:text-slate-50"
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
          class="text-sm font-medium whitespace-nowrap py-2.5 text-slate-900 dark:text-slate-50"
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
          class="text-sm font-medium whitespace-nowrap text-slate-900 py-2.5 dark:text-slate-50"
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
          class="text-sm font-medium whitespace-nowrap text-slate-900 py-2.5 dark:text-slate-50"
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
          class="text-sm font-medium whitespace-nowrap py-2.5 text-slate-900 dark:text-slate-50"
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
          class="text-sm font-medium whitespace-nowrap py-2.5 text-slate-900 dark:text-slate-50"
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
      <div class="flex items-start justify-between w-full gap-2">
        <label
          class="text-sm font-medium whitespace-nowrap py-2.5 text-slate-900 dark:text-slate-50"
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
