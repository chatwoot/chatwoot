<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import SectionLayout from './SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextInput from 'next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import ColorPicker from 'dashboard/components-next/colorpicker/ColorPicker.vue';

const { t } = useI18n();
const store = useStore();
const { currentAccount, updateAccount } = useAccount();

const ACCEPTED_LOGO_TYPES = 'image/png,image/jpeg,image/gif';

const brandName = ref('');
const brandUrl = ref('');
const brandColor = ref('');
const isSaving = ref(false);
const logoInput = ref(null);

const logoUrl = computed(() => currentAccount.value?.brand_logo_email_url);

// Seeded on the account's identity, not on every write to it: uploading a logo commits a
// fresh account to the store, and a deep watcher would use that to overwrite whatever the
// administrator had typed and not saved yet.
watch(
  () => currentAccount.value?.id,
  () => {
    const { brand_name, brand_url, brand_color } =
      currentAccount.value?.settings || {};
    brandName.value = brand_name || '';
    brandUrl.value = brand_url || '';
    brandColor.value = brand_color || '';
  },
  { immediate: true }
);

const save = async () => {
  isSaving.value = true;
  try {
    await updateAccount({
      brand_name: brandName.value,
      brand_url: brandUrl.value,
      brand_color: brandColor.value,
    });
    useAlert(t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.API.SUCCESS'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.API.ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const onLogoSelected = async event => {
  const [file] = event.target.files || [];
  // Clearing the input lets the same file be picked again after a failed upload.
  event.target.value = '';
  if (!file) return;

  try {
    await store.dispatch('accounts/updateBrandLogoEmail', file);
    useAlert(t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.API.LOGO_SUCCESS'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.API.LOGO_ERROR'));
  }
};

const removeLogo = async () => {
  try {
    await store.dispatch('accounts/deleteBrandLogoEmail');
    useAlert(t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.API.LOGO_REMOVED'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.API.LOGO_ERROR'));
  }
};
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.NOTE')"
    with-border
  >
    <form class="grid gap-4" @submit.prevent="save">
      <WithLabel
        name="brand-name"
        :label="t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.NAME.LABEL')"
      >
        <NextInput
          v-model="brandName"
          type="text"
          class="w-full"
          :placeholder="
            t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.NAME.PLACEHOLDER')
          "
        />
        <template #help>
          {{ t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.NAME.HELP') }}
        </template>
      </WithLabel>

      <WithLabel
        name="brand-url"
        :label="t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.URL.LABEL')"
      >
        <NextInput
          v-model="brandUrl"
          type="text"
          class="w-full"
          :placeholder="
            t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.URL.PLACEHOLDER')
          "
        />
      </WithLabel>

      <WithLabel
        name="brand-color"
        :label="t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.COLOR.LABEL')"
      >
        <div class="flex items-center gap-3">
          <ColorPicker v-model="brandColor" />
          <NextButton
            v-if="brandColor"
            link
            slate
            type="button"
            @click="brandColor = ''"
          >
            {{ t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.COLOR.RESET') }}
          </NextButton>
        </div>
        <template #help>
          {{ t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.COLOR.HELP') }}
        </template>
      </WithLabel>

      <WithLabel
        name="brand-logo-email"
        :label="t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.LOGO.LABEL')"
      >
        <div class="flex items-center gap-3">
          <img
            v-if="logoUrl"
            :src="logoUrl"
            :alt="t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.LOGO.LABEL')"
            class="h-9 w-auto max-w-40 object-contain"
          />
          <input
            ref="logoInput"
            type="file"
            class="hidden"
            :accept="ACCEPTED_LOGO_TYPES"
            @change="onLogoSelected"
          />
          <NextButton faded slate type="button" @click="logoInput.click()">
            {{
              logoUrl
                ? t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.LOGO.REPLACE')
                : t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.LOGO.UPLOAD')
            }}
          </NextButton>
          <NextButton
            v-if="logoUrl"
            faded
            ruby
            type="button"
            @click="removeLogo"
          >
            {{ t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.LOGO.REMOVE') }}
          </NextButton>
        </div>
        <template #help>
          {{ t('GENERAL_SETTINGS.FORM.EMAIL_BRANDING.LOGO.HELP') }}
        </template>
      </WithLabel>

      <div>
        <NextButton blue :is-loading="isSaving" type="submit">
          {{ t('GENERAL_SETTINGS.SUBMIT') }}
        </NextButton>
      </div>
    </form>
  </SectionLayout>
</template>
