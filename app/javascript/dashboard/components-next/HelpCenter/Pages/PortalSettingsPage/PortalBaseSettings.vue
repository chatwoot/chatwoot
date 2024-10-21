<script setup>
import { reactive, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { buildPortalURL } from 'dashboard/helper/portalHelper';

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

const state = reactive({
  name: '',
  headerText: '',
  pageTitle: '',
  slug: '',
  widgetColor: '',
  homePageLink: '',
  liveChatWidget: '',
});

const liveChatWidgets = [
  { value: 1, label: 'Chatwoot live chat' },
  { value: 2, label: 'Tidio live chat' },
];

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
      });
    }
  },
  { immediate: true, deep: true }
);

const handleUpdatePortal = () => {
  const portal = {
    id: props.activePortal.id,
    slug: state.slug,
    name: state.name,
    color: state.widgetColor,
    page_title: state.pageTitle,
    header_text: state.headerText,
    homepage_link: state.homePageLink,
  };
  emit('updatePortal', portal);
};

const handleUploadAvatar = () => {
  // Implement avatar upload logic
};
</script>

<template>
  <div class="flex flex-col w-full gap-4">
    <div class="flex flex-col w-full gap-2">
      <label class="mb-0.5 text-sm font-medium text-gray-900 dark:text-gray-50">
        {{ t('HELP_CENTER.PORTAL_SETTINGS.AVATAR.LABEL') }}
      </label>
      <Avatar
        label="Avatar"
        src="https://api.dicebear.com/9.x/avataaars/svg?seed=Amaya"
        class="bg-ruby-300 dark:bg-ruby-400"
        @upload="handleUploadAvatar"
      />
    </div>
    <div class="flex flex-col w-full gap-4">
      <div class="flex items-start justify-between w-full gap-2">
        <label
          class="text-sm font-medium whitespace-nowrap min-w-[100px] py-2.5 text-slate-900 dark:text-slate-50"
        >
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.NAME.LABEL') }}
        </label>
        <Input
          v-model="state.name"
          :placeholder="t('HELP_CENTER.PORTAL_SETTINGS.FORM.NAME.PLACEHOLDER')"
          class="w-[432px]"
          custom-input-class="!bg-transparent dark:!bg-transparent"
        />
      </div>
      <div class="flex items-start justify-between w-full gap-2">
        <label
          class="text-sm font-medium whitespace-nowrap min-w-[100px] py-2.5 text-slate-900 dark:text-slate-50"
        >
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.HEADER_TEXT.LABEL') }}
        </label>
        <Input
          v-model="state.headerText"
          :placeholder="
            t('HELP_CENTER.PORTAL_SETTINGS.FORM.HEADER_TEXT.PLACEHOLDER')
          "
          class="w-[432px]"
          custom-input-class="!bg-transparent dark:!bg-transparent"
        />
      </div>
      <div class="flex items-start justify-between w-full gap-2">
        <label
          class="text-sm font-medium whitespace-nowrap min-w-[100px] text-slate-900 py-2.5 dark:text-slate-50"
        >
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.PAGE_TITLE.LABEL') }}
        </label>
        <Input
          v-model="state.pageTitle"
          :placeholder="
            t('HELP_CENTER.PORTAL_SETTINGS.FORM.PAGE_TITLE.PLACEHOLDER')
          "
          class="w-[432px]"
          custom-input-class="!bg-transparent dark:!bg-transparent"
        />
      </div>
      <div class="flex items-start justify-between w-full gap-2">
        <label
          class="text-sm font-medium whitespace-nowrap min-w-[100px] text-slate-900 py-2.5 dark:text-slate-50"
        >
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.HOME_PAGE_LINK.LABEL') }}
        </label>
        <Input
          v-model="state.homePageLink"
          :placeholder="
            t('HELP_CENTER.PORTAL_SETTINGS.FORM.HOME_PAGE_LINK.PLACEHOLDER')
          "
          class="w-[432px]"
          custom-input-class="!bg-transparent dark:!bg-transparent"
        />
      </div>
      <div class="flex items-start justify-between w-full gap-2">
        <label
          class="text-sm font-medium whitespace-nowrap min-w-[100px] py-2.5 text-slate-900 dark:text-slate-50"
        >
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.SLUG.LABEL') }}
        </label>
        <Input
          v-model="state.slug"
          :placeholder="t('HELP_CENTER.PORTAL_SETTINGS.FORM.SLUG.PLACEHOLDER')"
          class="w-[432px]"
          :message="buildPortalURL(state.slug)"
          custom-input-class="!bg-transparent dark:!bg-transparent"
        />
      </div>
      <div class="flex items-start justify-between w-full gap-2">
        <label
          class="text-sm font-medium whitespace-nowrap min-w-[100px] py-2.5 text-slate-900 dark:text-slate-50"
        >
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.LIVE_CHAT_WIDGET.LABEL') }}
        </label>
        <ComboBox
          v-model="state.liveChatWidget"
          :options="liveChatWidgets"
          :placeholder="
            t('HELP_CENTER.PORTAL_SETTINGS.FORM.LIVE_CHAT_WIDGET.PLACEHOLDER')
          "
          :message="
            t('HELP_CENTER.PORTAL_SETTINGS.FORM.LIVE_CHAT_WIDGET.HELP_TEXT')
          "
          class="[&>button]:w-[432px] !w-[432px]"
        />
      </div>
      <div class="flex items-start justify-between w-full gap-2">
        <label
          class="text-sm font-medium whitespace-nowrap min-w-[100px] py-2.5 text-slate-900 dark:text-slate-50"
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
          @click="handleUpdatePortal"
        />
      </div>
    </div>
  </div>
</template>
