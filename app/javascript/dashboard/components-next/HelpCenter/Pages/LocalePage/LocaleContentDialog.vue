<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  portal: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);
const activeLocale = ref('');
const name = ref('');
const pageTitle = ref('');
const headerText = ref('');

const localeTranslations = computed(
  () => props.portal?.config?.locale_translations || {}
);

const openForLocale = localeCode => {
  const existing = localeTranslations.value[localeCode] || {};
  activeLocale.value = localeCode;
  name.value = existing.name || '';
  pageTitle.value = existing.page_title || '';
  headerText.value = existing.header_text || '';
  dialogRef.value?.open();
};

const onConfirm = async () => {
  const translations = { ...localeTranslations.value };
  const fields = {};
  if (name.value.trim()) fields.name = name.value.trim();
  if (pageTitle.value.trim()) fields.page_title = pageTitle.value.trim();
  if (headerText.value.trim()) fields.header_text = headerText.value.trim();

  if (Object.keys(fields).length) {
    translations[activeLocale.value] = fields;
  } else {
    delete translations[activeLocale.value];
  }

  try {
    await store.dispatch('portals/update', {
      portalSlug: props.portal?.slug,
      config: { locale_translations: translations },
    });
    dialogRef.value?.close();
    useAlert(t('HELP_CENTER.LOCALES_PAGE.CONTENT_DIALOG.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(
      error?.message ||
        t('HELP_CENTER.LOCALES_PAGE.CONTENT_DIALOG.API.ERROR_MESSAGE')
    );
  }
};

defineExpose({ openForLocale });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :title="t('HELP_CENTER.LOCALES_PAGE.CONTENT_DIALOG.TITLE')"
    :description="t('HELP_CENTER.LOCALES_PAGE.CONTENT_DIALOG.DESCRIPTION')"
    @confirm="onConfirm"
  >
    <div class="flex flex-col gap-4">
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('HELP_CENTER.LOCALES_PAGE.CONTENT_DIALOG.NAME.LABEL') }}
        </label>
        <Input v-model="name" :placeholder="portal.name" />
      </div>
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('HELP_CENTER.LOCALES_PAGE.CONTENT_DIALOG.PAGE_TITLE.LABEL') }}
        </label>
        <Input v-model="pageTitle" :placeholder="portal.page_title" />
      </div>
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('HELP_CENTER.LOCALES_PAGE.CONTENT_DIALOG.HEADER_TEXT.LABEL') }}
        </label>
        <Input v-model="headerText" :placeholder="portal.header_text" />
      </div>
    </div>
  </Dialog>
</template>
