<template>
  <div
    class="pt-3 bg-white dark:bg-slate-900 h-full border border-solid border-transparent px-6 pb-6 dark:border-transparent w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <div class="w-full">
      <h3 class="text-lg text-black-900 dark:text-slate-200">
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
          <div class="flex items-center flex-row">
            <woot-avatar-uploader
              ref="imageUpload"
              :label="$t('HELP_CENTER.PORTAL.ADD.LOGO.LABEL')"
              :src="logoUrl"
              @change="onFileChange"
            />
            <div v-if="showDeleteButton" class="avatar-delete-btn">
              <woot-button
                type="button"
                color-scheme="alert"
                variant="hollow"
                size="small"
                @click="deleteAvatar"
              >
                {{ $t('PROFILE_SETTINGS.DELETE_AVATAR') }}
              </woot-button>
            </div>
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
    <div class="flex justify-end">
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

import alertMixin from 'shared/mixins/alertMixin';
import { convertToCategorySlug } from 'dashboard/helper/commons.js';
import { buildPortalURL } from 'dashboard/helper/portalHelper';
import wootConstants from 'dashboard/constants/globals';
import { hasValidAvatarUrl } from 'dashboard/helper/URLHelper';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { uploadFile } from 'dashboard/helper/uploadHelper';

const { EXAMPLE_URL } = wootConstants;
const MAXIMUM_FILE_UPLOAD_SIZE = 4; // in MB

export default {
  mixins: [alertMixin],
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

      // Logouploader keys
      avatarBlobId: '',
      logoUrl: '',
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
    showDeleteButton() {
      return hasValidAvatarUrl(this.logoUrl);
    },
  },
  mounted() {
    const portal = this.portal || {};
    this.name = portal.name || '';
    this.slug = portal.slug || '';
    this.domain = portal.custom_domain || '';
    this.alertMessage = '';
    if (portal.logo) {
      const {
        logo: { file_url: logoURL, blob_id: blobId },
      } = portal;
      this.logoUrl = logoURL;
      this.avatarBlobId = blobId;
    }
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
        blob_id: this.avatarBlobId || null,
      };
      this.$emit('submit', portal);
    },
    async deleteAvatar() {
      this.logoUrl = '';
      this.avatarBlobId = '';
      this.$emit('delete-logo');
    },
    onFileChange({ file }) {
      if (checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) {
        this.uploadLogoToStorage(file);
      } else {
        this.showAlert(
          this.$t(
            'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.IMAGE_UPLOAD_SIZE_ERROR',
            {
              size: MAXIMUM_FILE_UPLOAD_SIZE,
            }
          )
        );
      }

      this.$refs.imageUpload.value = '';
    },
    async uploadLogoToStorage(file) {
      try {
        const { fileUrl, blobId } = await uploadFile(file);
        if (fileUrl) {
          this.logoUrl = fileUrl;
          this.avatarBlobId = blobId;
        }
      } catch (error) {
        this.showAlert(
          this.$t('HELP_CENTER.PORTAL.ADD.LOGO.IMAGE_DELETE_ERROR')
        );
      }
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
}
</style>
