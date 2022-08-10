<template>
  <modal :show.sync="show" :on-close="onClose">
    <woot-modal-header
      :header-title="$t('HELP_CENTER.PORTAL.ADD.TITLE')"
      :header-content="$t('HELP_CENTER.PORTAL.ADD.SUB_TITLE')"
    />
    <form class="row" @submit.prevent="onCreate">
      <div class="medium-12 columns">
        <woot-input
          v-model="name"
          :class="{ error: $v.name.$error }"
          class="medium-12 columns"
          :error="$v.name.$error ? $t('HELP_CENTER.PORTAL.ADD.NAME.ERROR') : ''"
          :label="$t('HELP_CENTER.PORTAL.ADD.NAME.LABEL')"
          :placeholder="$t('HELP_CENTER.PORTAL.ADD.NAME.PLACEHOLDER')"
          :help-text="$t('HELP_CENTER.PORTAL.ADD.NAME.HELP_TEXT')"
          @blur="$v.name.$touch"
          @input="onNameChange"
        />
        <woot-input
          v-model="slug"
          :class="{ error: $v.slug.$error }"
          class="medium-12 columns"
          :error="$v.slug.$error ? $t('HELP_CENTER.PORTAL.ADD.SLUG.ERROR') : ''"
          :label="$t('HELP_CENTER.PORTAL.ADD.SLUG.LABEL')"
          :placeholder="$t('HELP_CENTER.PORTAL.ADD.SLUG.PLACEHOLDER')"
          :help-text="$t('HELP_CENTER.PORTAL.ADD.SLUG.HELP_TEXT')"
          @blur="$v.slug.$touch"
        />

        <woot-input
          v-model="pageTitle"
          class="medium-12 columns"
          :label="$t('HELP_CENTER.PORTAL.ADD.PAGE_TITLE.LABEL')"
          :placeholder="$t('HELP_CENTER.PORTAL.ADD.PAGE_TITLE.PLACEHOLDER')"
          :help-text="$t('HELP_CENTER.PORTAL.ADD.PAGE_TITLE.HELP_TEXT')"
        />
        <woot-input
          v-model="headerText"
          class="medium-12 columns"
          :label="$t('HELP_CENTER.PORTAL.ADD.HEADER_TEXT.LABEL')"
          :placeholder="$t('HELP_CENTER.PORTAL.ADD.HEADER_TEXT.PLACEHOLDER')"
          :help-text="$t('HELP_CENTER.PORTAL.ADD.HEADER_TEXT.HELP_TEXT')"
        />

        <woot-input
          v-model="domain"
          class="medium-12 columns"
          :label="$t('HELP_CENTER.PORTAL.ADD.DOMAIN.LABEL')"
          :placeholder="$t('HELP_CENTER.PORTAL.ADD.DOMAIN.PLACEHOLDER')"
          :help-text="$t('HELP_CENTER.PORTAL.ADD.DOMAIN.HELP_TEXT')"
        />
        <woot-input
          v-model="homePageLink"
          class="medium-12 columns"
          :label="$t('HELP_CENTER.PORTAL.ADD.HOME_PAGE_LINK.LABEL')"
          :placeholder="$t('HELP_CENTER.PORTAL.ADD.HOME_PAGE_LINK.PLACEHOLDER')"
          :help-text="$t('HELP_CENTER.PORTAL.ADD.HOME_PAGE_LINK.HELP_TEXT')"
        />

        <div class="medium-12 columns">
          <div class="modal-footer justify-content-end w-full">
            <woot-button
              class="button clear"
              :is-loading="uiFlags.isCreating"
              @click.prevent="onClose"
            >
              {{ $t('HELP_CENTER.PORTAL.ADD.BUTTONS.CANCEL') }}
            </woot-button>
            <woot-button>
              {{ $t('HELP_CENTER.PORTAL.ADD.BUTTONS.CREATE') }}
            </woot-button>
          </div>
        </div>
      </div>
    </form>
  </modal>
</template>

<script>
import { mapGetters } from 'vuex';
import Modal from 'dashboard/components/Modal';
import alertMixin from 'shared/mixins/alertMixin';
import { required } from 'vuelidate/lib/validators';
import { convertToPortalSlug } from 'dashboard/helper/commons.js';

export default {
  components: {
    Modal,
  },
  mixins: [alertMixin],
  props: {
    show: {
      type: Boolean,
      default: true,
    },
    portalName: {
      type: String,
      default: '',
    },
    locale: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      name: '',
      slug: '',
      domain: '',
      homePageLink: '',
      pageTitle: '',
      headerText: '',
      alertMessage: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'portals/uiFlagsIn',
    }),
  },
  validations: {
    name: {
      required,
    },
    slug: {
      required,
    },
  },
  methods: {
    onNameChange() {
      this.slug = convertToPortalSlug(this.name);
    },
    async onCreate() {
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
            // TODO: add support for choosing color
            color: '#1f93ff',
            homepage_link: this.homePageLink,
            page_title: this.pageTitle,
            header_text: this.headerText,
            config: {
              // TODO: add support for choosing locale
              allowed_locales: ['en'],
            },
          },
        });
        this.alertMessage = this.$t(
          'HELP_CENTER.PORTAL.ADD.API.SUCCESS_MESSAGE'
        );
        this.$emit('cancel');
      } catch (error) {
        this.alertMessage =
          error?.message || this.$t('HELP_CENTER.PORTAL.ADD.API.ERROR_MESSAGE');
      } finally {
        this.showAlert(this.alertMessage);
      }
    },
    onClose() {
      this.$emit('cancel');
    },
  },
};
</script>
<style scoped lang="scss">
.input-container::v-deep {
  margin: 0 0 var(--space-normal);

  input {
    margin-bottom: 0;
  }
  .message {
    margin-top: 0;
  }
}
</style>
