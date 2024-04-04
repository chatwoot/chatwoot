<template>
  <div
    class="pt-3 bg-white dark:bg-slate-900 h-full border border-solid border-transparent px-6 pb-6 dark:border-transparent w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <div class="w-full">
      <h3 class="text-lg text-black-900 dark:text-slate-200">
        {{
          $t('HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.CUSTOMIZATION_PAGE.TITLE')
        }}
      </h3>
    </div>
    <div
      class="my-4 mx-0 border-b border-solid border-slate-25 dark:border-slate-800"
    >
      <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
        <div class="mb-4">
          <label>
            {{ $t('HELP_CENTER.PORTAL.ADD.THEME_COLOR.LABEL') }}
          </label>
          <woot-color-picker v-model="color" />
          <p
            class="mt-1 mb-0 text-xs text-slate-600 dark:text-slate-400 not-italic"
          >
            {{ $t('HELP_CENTER.PORTAL.ADD.THEME_COLOR.HELP_TEXT') }}
          </p>
        </div>
        <div class="mb-4">
          <woot-input
            v-model.trim="pageTitle"
            :label="$t('HELP_CENTER.PORTAL.ADD.PAGE_TITLE.LABEL')"
            :placeholder="$t('HELP_CENTER.PORTAL.ADD.PAGE_TITLE.PLACEHOLDER')"
            :help-text="$t('HELP_CENTER.PORTAL.ADD.PAGE_TITLE.HELP_TEXT')"
          />
        </div>
        <div class="mb-4">
          <woot-input
            v-model.trim="headerText"
            :label="$t('HELP_CENTER.PORTAL.ADD.HEADER_TEXT.LABEL')"
            :placeholder="$t('HELP_CENTER.PORTAL.ADD.HEADER_TEXT.PLACEHOLDER')"
            :help-text="$t('HELP_CENTER.PORTAL.ADD.HEADER_TEXT.HELP_TEXT')"
          />
        </div>
        <div class="mb-4">
          <woot-input
            v-model.trim="homePageLink"
            :label="$t('HELP_CENTER.PORTAL.ADD.HOME_PAGE_LINK.LABEL')"
            :placeholder="
              $t('HELP_CENTER.PORTAL.ADD.HOME_PAGE_LINK.PLACEHOLDER')
            "
            :help-text="homepageExampleHelpText"
            :error="
              $v.homePageLink.$error
                ? $t('HELP_CENTER.PORTAL.ADD.HOME_PAGE_LINK.ERROR')
                : ''
            "
            :class="{ error: $v.homePageLink.$error }"
            @blur="$v.homePageLink.$touch"
          />
        </div>
      </div>
    </div>
    <div class="flex justify-end">
      <woot-button
        :is-loading="isSubmitting"
        :is-disabled="$v.$invalid"
        @click="onSubmitClick"
      >
        {{
          $t(
            'HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.CUSTOMIZATION_PAGE.UPDATE_PORTAL_BUTTON'
          )
        }}
      </woot-button>
    </div>
  </div>
</template>

<script>
import { url } from 'vuelidate/lib/validators';
import { getRandomColor } from 'dashboard/helper/labelColor';

import alertMixin from 'shared/mixins/alertMixin';
import wootConstants from 'dashboard/constants/globals';

const { EXAMPLE_URL } = wootConstants;

export default {
  components: {},
  mixins: [alertMixin],
  props: {
    portal: {
      type: Object,
      default: () => ({}),
    },
    isSubmitting: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      color: '#000',
      pageTitle: '',
      headerText: '',
      homePageLink: '',
      alertMessage: '',
    };
  },
  validations: {
    homePageLink: {
      url,
    },
  },
  computed: {
    homepageExampleHelpText() {
      return this.$t('HELP_CENTER.PORTAL.ADD.HOME_PAGE_LINK.HELP_TEXT', {
        exampleURL: EXAMPLE_URL,
      });
    },
  },
  mounted() {
    this.color = getRandomColor();
    this.updateDataFromStore();
  },
  methods: {
    updateDataFromStore() {
      const { portal } = this;
      if (portal) {
        this.color = portal.color || getRandomColor();
        this.pageTitle = portal.page_title || '';
        this.headerText = portal.header_text || '';
        this.homePageLink = portal.homepage_link || '';
        this.alertMessage = '';
      }
    },
    onSubmitClick() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      const portal = {
        id: this.portal.id,
        slug: this.portal.slug,
        color: this.color,
        page_title: this.pageTitle,
        header_text: this.headerText,
        homepage_link: this.homePageLink,
      };
      this.$emit('submit', portal);
    },
  },
};
</script>
<style lang="scss" scoped>
::v-deep {
  input {
    @apply mb-1;
  }
  .help-text {
    @apply mb-0;
  }
  .colorpicker--selected {
    @apply mb-0;
  }
}
</style>
