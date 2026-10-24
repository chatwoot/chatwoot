<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  portalSlug: { type: String, required: true },
  portalName: { type: String, default: '' },
});

// { light: { url, blobId }, dark: { url, blobId } }; `blobId` is only set for
// a new upload, since saved logos are already attached.
const logos = defineModel({ type: Object, required: true });

const { t } = useI18n();
const store = useStore();

const MAXIMUM_FILE_UPLOAD_SIZE = 4; // in MB

const isAddingDarkLogo = ref(false);

const showDarkLogo = computed(
  () => isAddingDarkLogo.value || !!logos.value.dark.url
);

const setLogo = (key, logo) => {
  logos.value = { ...logos.value, [key]: logo };
};

const handleLogoUpload = async (payload, key) => {
  if (!checkFileSizeLimit(payload, MAXIMUM_FILE_UPLOAD_SIZE)) {
    useAlert(
      t('HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.IMAGE_UPLOAD_SIZE_ERROR', {
        size: MAXIMUM_FILE_UPLOAD_SIZE,
      })
    );
    return;
  }
  try {
    const { fileUrl, blobId } = await uploadFile(payload.file);
    setLogo(key, { url: fileUrl, blobId });
    useAlert(t('HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.IMAGE_UPLOAD_SUCCESS'));
  } catch (error) {
    useAlert(t('HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.IMAGE_UPLOAD_ERROR'));
  }
};

const handleLogoDelete = async key => {
  try {
    await store.dispatch('portals/deleteLogo', {
      portalSlug: props.portalSlug,
      isDarkLogo: key === 'dark',
    });
    setLogo(key, { url: '', blobId: '' });
    if (key === 'dark') isAddingDarkLogo.value = false;
    useAlert(t('HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.IMAGE_DELETE_SUCCESS'));
  } catch (error) {
    useAlert(
      error?.message ||
        t('HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.IMAGE_DELETE_ERROR')
    );
  }
};
</script>

<template>
  <div
    class="grid items-start justify-between w-full gap-2 grid-cols-[200px,1fr]"
  >
    <label class="text-sm font-medium whitespace-nowrap py-2.5 text-n-slate-12">
      {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.LABEL') }}
    </label>
    <div class="flex items-center gap-6">
      <div class="flex flex-col items-center gap-2">
        <Avatar
          :src="logos.light.url"
          :name="portalName"
          :size="72"
          allow-upload
          icon-name="i-lucide-building-2"
          @upload="payload => handleLogoUpload(payload, 'light')"
          @delete="handleLogoDelete('light')"
        />
        <span v-if="showDarkLogo" class="text-xs text-n-slate-11">
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.LIGHT_MODE') }}
        </span>
      </div>
      <div v-if="showDarkLogo" class="flex flex-col items-center gap-2">
        <Avatar
          :src="logos.dark.url"
          :name="portalName"
          :size="72"
          allow-upload
          icon-name="i-lucide-building-2"
          @upload="payload => handleLogoUpload(payload, 'dark')"
          @delete="handleLogoDelete('dark')"
        />
        <span class="text-xs text-n-slate-11">
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.DARK_MODE') }}
        </span>
      </div>
      <Button
        v-else
        :label="t('HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.ADD_DARK_MODE')"
        icon="i-lucide-plus"
        color="slate"
        variant="link"
        size="sm"
        @click="isAddingDarkLogo = true"
      />
    </div>
  </div>
</template>
