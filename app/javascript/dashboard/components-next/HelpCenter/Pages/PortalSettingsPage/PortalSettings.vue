<script setup>
import { computed, reactive, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';

import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  portals: {
    type: Array,
    required: true,
  },
  isFetching: {
    type: Boolean,
    required: true,
  },
});

const emit = defineEmits([
  'updatePortal',
  'updatePortalConfiguration',
  'deletePortal',
]);

const { t } = useI18n();
const route = useRoute();

const currentPortalSlug = computed(() => route.params.portalSlug);

const activePortal = computed(() => {
  return props.portals?.find(portal => portal.slug === currentPortalSlug.value);
});

const activePortalName = computed(() => activePortal.value?.name);

const state = reactive({
  name: '',
  headerText: '',
  pageTitle: '',
  widgetColor: '',
});

const configurationState = reactive({
  slug: '',
  customDomain: '',
  homePageLink: '',
});

watch(activePortal, newVal => {
  if (newVal && !props.isFetching) {
    state.name = newVal.name;
    state.headerText = newVal.header_text;
    state.pageTitle = newVal.page_title;
    state.widgetColor = newVal.color;
  }
});

watch(activePortal, newVal => {
  if (newVal && !props.isFetching) {
    configurationState.slug = newVal.slug;
    configurationState.customDomain = newVal.custom_domain;
    configurationState.homePageLink = newVal.homepage_link;
  }
});

const handleUpdatePortal = () => {
  const portal = {
    id: activePortal.value.id,
    slug: activePortal.value.slug,
    name: state.name,
    color: state.widgetColor,
    page_title: state.pageTitle,
    header_text: state.headerText,
  };
  emit('updatePortal', portal);
};

const handleUpdatePortalConfiguration = () => {
  const portal = {
    id: activePortal.value.id,
    slug: activePortal.value.slug,
    custom_domain: configurationState.customDomain,
    homepage_link: configurationState.homePageLink,
  };
  emit('updatePortalConfiguration', portal);
};

const deletePortal = () => {
  emit('deletePortal', activePortal.value);
};

const handleUploadAvatar = () => {};
</script>

<template>
  <HelpCenterLayout :show-pagination-footer="false">
    <template #content>
      <div
        v-if="!isFetching && activePortal"
        class="flex flex-col w-full gap-10 max-w-[640px] pt-2 pb-8"
      >
        <div class="flex flex-col w-full gap-4">
          <div class="flex flex-col w-full gap-2">
            <label
              class="mb-0.5 text-sm font-medium text-gray-900 dark:text-gray-50"
            >
              {{ t('HELP_CENTER.PORTAL_SETTINGS.AVATAR.LABEL') }}
            </label>
            <Avatar
              label="Avatar"
              src="https://api.dicebear.com/9.x/avataaars/svg?seed=Amaya"
              class="bg-ruby-300 dark:bg-ruby-400"
              @upload="handleUploadAvatar"
            />
          </div>
          <div class="flex flex-col w-full gap-2">
            <div class="flex justify-between w-full h-10 gap-2 py-1">
              <label
                class="text-sm font-medium whitespace-nowrap min-w-[100px] text-slate-900 dark:text-slate-50"
              >
                {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.NAME.LABEL') }}
              </label>
              <Input
                v-model="state.name"
                :placeholder="
                  t('HELP_CENTER.PORTAL_SETTINGS.FORM.NAME.PLACEHOLDER')
                "
                class="w-[432px]"
              />
            </div>
            <div class="flex justify-between w-full h-10 gap-2 py-1">
              <label
                class="text-sm font-medium whitespace-nowrap min-w-[100px] text-slate-900 dark:text-slate-50"
              >
                {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.HEADER_TEXT.LABEL') }}
              </label>
              <Input
                v-model="state.headerText"
                :placeholder="
                  t('HELP_CENTER.PORTAL_SETTINGS.FORM.HEADER_TEXT.PLACEHOLDER')
                "
                class="w-[432px]"
              />
            </div>
            <div class="flex justify-between w-full h-10 gap-2 py-1">
              <label
                class="text-sm font-medium whitespace-nowrap min-w-[100px] text-slate-900 dark:text-slate-50"
              >
                {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.PAGE_TITLE.LABEL') }}
              </label>
              <Input
                v-model="state.pageTitle"
                :placeholder="
                  t('HELP_CENTER.PORTAL_SETTINGS.FORM.PAGE_TITLE.PLACEHOLDER')
                "
                class="w-[432px]"
              />
            </div>
            <div class="flex justify-between w-full h-10 gap-2 py-1">
              <label
                class="text-sm font-medium whitespace-nowrap min-w-[100px] text-slate-900 dark:text-slate-50"
              >
                {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.WIDGET_COLOR.LABEL') }}
              </label>
            </div>
            <div class="flex justify-end w-full gap-2 py-2">
              <Button
                :label="t('HELP_CENTER.PORTAL_SETTINGS.FORM.SAVE_CHANGES')"
                size="sm"
                @click="handleUpdatePortal"
              />
            </div>
          </div>
          <div class="w-full h-px bg-slate-50 dark:bg-slate-800/50" />
        </div>
        <div class="flex flex-col w-full gap-6">
          <div class="flex flex-col w-full gap-6">
            <h6 class="text-base font-medium text-slate-900 dark:text-slate-50">
              {{ t('HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.HEADER') }}
            </h6>
            <div class="flex flex-col w-full gap-4">
              <div class="flex justify-between w-full gap-2 py-1">
                <InlineInput
                  v-model="configurationState.slug"
                  :placeholder="
                    t(
                      'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.SLUG.PLACEHOLDER'
                    )
                  "
                  :label="
                    t(
                      'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.SLUG.LABEL'
                    )
                  "
                  custom-label-class="min-w-[100px]"
                  custom-input-class="!w-[430px]"
                />
              </div>
              <div class="flex justify-between w-full gap-2 py-1">
                <InlineInput
                  v-model="configurationState.customDomain"
                  :placeholder="
                    t(
                      'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.PLACEHOLDER'
                    )
                  "
                  :label="
                    t(
                      'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.LABEL'
                    )
                  "
                  custom-label-class="min-w-[100px]"
                  custom-input-class="!w-[430px]"
                />
              </div>
              <div class="flex justify-between w-full gap-2 py-1">
                <InlineInput
                  v-model="configurationState.homePageLink"
                  :placeholder="
                    t(
                      'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.HOME_PAGE_LINK.PLACEHOLDER'
                    )
                  "
                  :label="
                    t(
                      'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.HOME_PAGE_LINK.LABEL'
                    )
                  "
                  custom-label-class="min-w-[100px]"
                  custom-input-class="!w-[430px]"
                />
              </div>
            </div>
          </div>
          <div class="flex justify-end w-full gap-3 py-4">
            <Button
              :label="
                t(
                  'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.EDIT_CONFIGURATION'
                )
              "
              size="sm"
              variant="secondary"
              @click="handleUpdatePortalConfiguration"
            />
            <Button
              :label="
                t(
                  'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.DELETE_PORTAL',
                  { portalName: activePortalName }
                )
              "
              size="sm"
              variant="destructive"
              @click="deletePortal"
            />
          </div>
        </div>
      </div>
      <div
        v-else
        class="flex items-center justify-center py-10 pt-2 pb-8 text-n-slate-11"
      >
        <Spinner />
      </div>
    </template>
  </HelpCenterLayout>
</template>
