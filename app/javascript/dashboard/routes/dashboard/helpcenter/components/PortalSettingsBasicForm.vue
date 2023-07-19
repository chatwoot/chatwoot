<template>
  <div class="wizard-body w-[75%] flex-shrink-0 flex-grow-0 max-w-[75%]">
    <div class="w-full">
      <h3 class="block-title text-black-900 dark:text-slate-200">
        {{
          $t(
            'HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.BASIC_SETTINGS_PAGE.TITLE'
          )
        }}
      </h3>
    </div>
    <div
      class="my-4 mx-0 border-b border-solid border-slate-25 dark:border-slate-800"
    >
      <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
        <div class="mb-4">
          <label>
            {{ $t('HELP_CENTER.PORTAL.ADD.LOGO.LABEL') }}
          </label>
          <div class="flex items-center flex-row">
            <thumbnail :username="name" size="56px" variant="square" />
            <woot-button
              v-if="false"
              class="ml-3"
              variant="smooth"
              color-scheme="secondary"
              icon="upload"
              size="small"
            >
              {{ $t('HELP_CENTER.PORTAL.ADD.LOGO.UPLOAD_BUTTON') }}
            </woot-button>
          </div>
          <p
            class="mt-1 mb-0 text-xs text-slate-600 dark:text-slate-400 not-italic"
          >
            {{ $t('HELP_CENTER.PORTAL.ADD.LOGO.HELP_TEXT') }}
          </p>
        </div>
        <div class="mb-4">
          <woot-input
            v-model.trim="name"
            :class="{ error: $v.name.$error }"
            :error="nameError"
            :label="$t('HELP_CENTER.PORTAL.ADD.NAME.LABEL')"
            :placeholder="$t('HELP_CENTER.PORTAL.ADD.NAME.PLACEHOLDER')"
            :help-text="$t('HELP_CENTER.PORTAL.ADD.NAME.HELP_TEXT')"
            @blur="$v.name.$touch"
            @input="onNameChange"
          />
        </div>
        <div class="mb-4">
          <woot-input
            v-model.trim="slug"
            :class="{ error: $v.slug.$error }"
            :error="slugError"
            :label="$t('HELP_CENTER.PORTAL.ADD.SLUG.LABEL')"
            :placeholder="$t('HELP_CENTER.PORTAL.ADD.SLUG.PLACEHOLDER')"
            :help-text="domainHelpText"
            @blur="$v.slug.$touch"
          />
        </div>
        <div class="mb-4">
          <woot-input
            v-model.trim="domain"
            :class="{ error: $v.domain.$error }"
            :label="$t('HELP_CENTER.PORTAL.ADD.DOMAIN.LABEL')"
            :placeholder="$t('HELP_CENTER.PORTAL.ADD.DOMAIN.PLACEHOLDER')"
            :help-text="domainExampleHelpText"
            :error="domainError"
            @blur="$v.domain.$touch"
          />
        </div>
      </div>
    </div>
    <div class="flex-end">
      <woot-button
        :is-loading="isSubmitting"
        :is-disabled="$v.$invalid"
        @click="onSubmitClick"
      >
        {{ submitButtonText }}
      </woot-button>
    </div>
  </div>
</template>

<script>
import { required, minLength } from 'vuelidate/lib/validators';
import { isDomain } from 'shared/helpers/Validators';
import thumbnail from 'dashboard/components/widgets/Thumbnail';
import { convertToCategorySlug } from 'dashboard/helper/commons.js';
import { buildPortalURL } from 'dashboard/helper/portalHelper';
import wootConstants from 'dashboard/constants/globals';

const { EXAMPLE_URL } = wootConstants;

export default {
  components: {
    thumbnail,
  },
  props: {
    portal: {
      type: Object,
      default: () => {},
    },
    isSubmitting: {
      type: Boolean,
      default: false,
    },
    submitButtonText: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      name: '',
      slug: '',
      domain: '',
      alertMessage: '',
    };
  },
  validations: {
    name: {
      required,
      minLength: minLength(2),
    },
    slug: {
      required,
    },
    domain: {
      isDomain,
    },
  },
  computed: {
    nameError() {
      if (this.$v.name.$error) {
        return this.$t('HELP_CENTER.CATEGORY.ADD.NAME.ERROR');
      }
      return '';
    },
    slugError() {
      if (this.$v.slug.$error) {
        return this.$t('HELP_CENTER.CATEGORY.ADD.SLUG.ERROR');
      }
      return '';
    },
    domainError() {
      if (this.$v.domain.$error) {
        return this.$t('HELP_CENTER.PORTAL.ADD.DOMAIN.ERROR');
      }
      return '';
    },
    domainHelpText() {
      return buildPortalURL(this.slug);
    },
    domainExampleHelpText() {
      return this.$t('HELP_CENTER.PORTAL.ADD.DOMAIN.HELP_TEXT', {
        exampleURL: EXAMPLE_URL,
      });
    },
  },
  mounted() {
    const portal = this.portal || {};
    this.name = portal.name || '';
    this.slug = portal.slug || '';
    this.domain = portal.custom_domain || '';
    this.alertMessage = '';
  },
  methods: {
    onNameChange() {
      this.slug = convertToCategorySlug(this.name);
    },
    onSubmitClick() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }

      const portal = {
        name: this.name,
        slug: this.slug,
        custom_domain: this.domain,
      };
      this.$emit('submit', portal);
    },
  },
};
</script>
<style lang="scss" scoped>
.wizard-body {
  @apply pt-3 border border-solid border-transparent dark:border-transparent;
}

::v-deep {
  input {
    @apply mb-1;
  }
  .help-text {
    @apply mb-0;
  }
}
</style>
