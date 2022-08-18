<template>
  <div class="wizard-body columns content-box small-9">
    <div class="medium-12 columns">
      <h3 class="block-title">
        {{
          $t(
            'HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.BASIC_SETTINGS_PAGE.TITLE'
          )
        }}
      </h3>
    </div>
    <div class="portal-form">
      <div class="medium-8 columns">
        <div class="form-item">
          <label>
            {{ $t('HELP_CENTER.PORTAL.ADD.LOGO.LABEL') }}
          </label>
          <div class="logo-container">
            <thumbnail :username="name" size="56" variant="square" />
            <woot-button
              class="upload-button"
              variant="smooth"
              color-scheme="secondary"
              icon="upload"
              size="small"
            >
              {{ $t('HELP_CENTER.PORTAL.ADD.LOGO.UPLOAD_BUTTON') }}
            </woot-button>
          </div>
          <p class="logo-help--text">
            {{ $t('HELP_CENTER.PORTAL.ADD.LOGO.HELP_TEXT') }}
          </p>
        </div>
        <div class="form-item">
          <woot-input
            v-model.trim="name"
            :class="{ error: $v.slug.$error }"
            :error="nameError"
            :label="$t('HELP_CENTER.PORTAL.ADD.NAME.LABEL')"
            :placeholder="$t('HELP_CENTER.PORTAL.ADD.NAME.PLACEHOLDER')"
            :help-text="$t('HELP_CENTER.PORTAL.ADD.NAME.HELP_TEXT')"
            @input="onNameChange"
          />
        </div>
        <div class="form-item">
          <woot-input
            v-model.trim="slug"
            :class="{ error: $v.slug.$error }"
            :error="slugError"
            :label="$t('HELP_CENTER.PORTAL.ADD.SLUG.LABEL')"
            :placeholder="$t('HELP_CENTER.PORTAL.ADD.SLUG.PLACEHOLDER')"
            :help-text="$t('HELP_CENTER.PORTAL.ADD.SLUG.HELP_TEXT')"
            @input="$v.slug.$touch"
          />
        </div>
        <div class="form-item">
          <woot-input
            v-model.trim="domain"
            :label="$t('HELP_CENTER.PORTAL.ADD.DOMAIN.LABEL')"
            :placeholder="$t('HELP_CENTER.PORTAL.ADD.DOMAIN.PLACEHOLDER')"
            :help-text="$t('HELP_CENTER.PORTAL.ADD.DOMAIN.HELP_TEXT')"
          />
        </div>
      </div>
    </div>
    <div class="flex-end">
      <woot-button
        :is-loading="uiFlags.isCreating"
        :is-disabled="$v.$invalid"
        @click="updateBasicSettings"
      >
        {{
          $t(
            'HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.BASIC_SETTINGS_PAGE.CREATE_BASIC_SETTING_BUTTON'
          )
        }}
      </woot-button>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import thumbnail from 'dashboard/components/widgets/Thumbnail';
import alertMixin from 'shared/mixins/alertMixin';
import { required, minLength } from 'vuelidate/lib/validators';
import { convertToCategorySlug } from 'dashboard/helper/commons.js';
export default {
  components: {
    thumbnail,
  },
  mixins: [alertMixin],
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
  },
  computed: {
    ...mapGetters({
      uiFlags: 'portals/uiFlagsIn',
    }),
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
      return this.$v.domain.$error;
    },
  },

  methods: {
    onNameChange() {
      this.slug = convertToCategorySlug(this.name);
    },
    async updateBasicSettings() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      try {
        await this.$store.dispatch('portals/create', {
          portal: {
            name: this.name,
            slug: this.slug,
            custom_domain: this.domain,
          },
        });
        this.alertMessage = this.$t(
          'HELP_CENTER.PORTAL.ADD.API.SUCCESS_MESSAGE_FOR_BASIC'
        );
      } catch (error) {
        this.alertMessage =
          error?.message ||
          this.$t('HELP_CENTER.PORTAL.ADD.API.ERROR_MESSAGE_FOR_BASIC');
      } finally {
        this.$router.push({
          name: 'portal_customization',
          params: { portal_slug: this.slug },
        });
      }
    },
  },
};
</script>
<style lang="scss" scoped>
.wizard-body {
  padding-top: var(--space-slab);
  border: 1px solid transparent;
}

.portal-form {
  margin: var(--space-normal) 0;
  border-bottom: 1px solid var(--s-25);

  .form-item {
    margin-bottom: var(--space-normal);

    .logo-container {
      display: flex;
      align-items: center;
      flex-direction: row;
      .upload-button {
        margin-left: var(--space-slab);
      }
    }
    .logo-help--text {
      margin-top: var(--space-smaller);
      margin-bottom: 0;
      font-size: var(--font-size-mini);
      color: var(--s-600);
      font-style: normal;
    }
  }
}
::v-deep {
  input {
    margin-bottom: var(--space-smaller);
  }
  .help-text {
    margin-bottom: 0;
  }
}
</style>
