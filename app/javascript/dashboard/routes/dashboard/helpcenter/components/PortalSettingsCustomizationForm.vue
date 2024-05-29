<script setup>
import { getRandomColor } from 'dashboard/helper/labelColor';
import SettingsLayout from './Layout/SettingsLayout.vue';
import wootConstants from 'dashboard/constants/globals';
const { EXAMPLE_URL } = wootConstants;

import { useVuelidate } from '@vuelidate/core';
import { url } from '@vuelidate/validators';

import { defineComponent, reactive, computed, onMounted } from 'vue';
import { useI18n } from 'dashboard/composables/useI18n';

defineComponent({
  name: 'PortalSettingsCustomizationForm',
});

const { t } = useI18n();

const props = defineProps({
  portal: {
    type: Object,
    default: () => ({}),
  },
  isSubmitting: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['submit']);

const state = reactive({
  color: getRandomColor(),
  pageTitle: '',
  headerText: '',
  homePageLink: '',
});

const rules = {
  homePageLink: { url },
};

const homepageExampleHelpText = computed(() => {
  return t('HELP_CENTER.PORTAL.ADD.HOME_PAGE_LINK.HELP_TEXT', {
    exampleURL: EXAMPLE_URL,
  });
});

const v$ = useVuelidate(rules, state);

function updateDataFromStore() {
  const { portal } = props;
  if (portal) {
    state.color = portal.color || getRandomColor();
    state.pageTitle = portal.page_title || '';
    state.headerText = portal.header_text || '';
    state.homePageLink = portal.homepage_link || '';
  }
}

function onSubmitClick() {
  v$.value.$touch();
  if (v$.value.$invalid) {
    return;
  }

  const portal = {
    id: props.portal.id,
    slug: props.portal.slug,
    color: state.color,
    page_title: state.pageTitle,
    header_text: state.headerText,
    homepage_link: state.homePageLink,
  };

  emit('submit', portal);
}

onMounted(() => {
  updateDataFromStore();
});
</script>

<template>
  <SettingsLayout
    :title="
      $t('HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.CUSTOMIZATION_PAGE.TITLE')
    "
  >
    <div class="flex-grow-0 flex-shrink-0">
      <div class="mb-4">
        <label>
          {{ $t('HELP_CENTER.PORTAL.ADD.THEME_COLOR.LABEL') }}
        </label>
        <woot-color-picker v-model="state.color" />
        <p
          class="mt-1 mb-0 text-xs not-italic text-slate-600 dark:text-slate-400"
        >
          {{ $t('HELP_CENTER.PORTAL.ADD.THEME_COLOR.HELP_TEXT') }}
        </p>
      </div>
      <div class="mb-4">
        <woot-input
          v-model="state.pageTitle"
          :label="$t('HELP_CENTER.PORTAL.ADD.PAGE_TITLE.LABEL')"
          :placeholder="$t('HELP_CENTER.PORTAL.ADD.PAGE_TITLE.PLACEHOLDER')"
          :help-text="$t('HELP_CENTER.PORTAL.ADD.PAGE_TITLE.HELP_TEXT')"
        />
      </div>
      <div class="mb-4">
        <woot-input
          v-model="state.headerText"
          :label="$t('HELP_CENTER.PORTAL.ADD.HEADER_TEXT.LABEL')"
          :placeholder="$t('HELP_CENTER.PORTAL.ADD.HEADER_TEXT.PLACEHOLDER')"
          :help-text="$t('HELP_CENTER.PORTAL.ADD.HEADER_TEXT.HELP_TEXT')"
        />
      </div>
      <div class="mb-4">
        <woot-input
          v-model="state.homePageLink"
          :label="$t('HELP_CENTER.PORTAL.ADD.HOME_PAGE_LINK.LABEL')"
          :placeholder="$t('HELP_CENTER.PORTAL.ADD.HOME_PAGE_LINK.PLACEHOLDER')"
          :help-text="homepageExampleHelpText"
          :error="
            v$.homePageLink.$error
              ? $t('HELP_CENTER.PORTAL.ADD.HOME_PAGE_LINK.ERROR')
              : ''
          "
          :class="{ error: v$.homePageLink.$error }"
          @blur="v$.homePageLink.$touch"
        />
      </div>
    </div>
    <template #footer-right>
      <woot-button
        :is-loading="isSubmitting"
        :is-disabled="v$.$invalid"
        @click="onSubmitClick"
      >
        {{
          $t(
            'HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.CUSTOMIZATION_PAGE.UPDATE_PORTAL_BUTTON'
          )
        }}
      </woot-button>
    </template>
  </SettingsLayout>
</template>

<style lang="scss" scoped>
::v-deep {
  .colorpicker--selected {
    @apply mb-0;
  }
}
</style>
