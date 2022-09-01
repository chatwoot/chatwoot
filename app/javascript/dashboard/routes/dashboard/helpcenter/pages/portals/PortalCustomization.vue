<template>
  <div class="wizard-body height-auto small-9 columns">
    <div class="medium-12 columns">
      <h3 class="block-title">
        {{
          $t('HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.CUSTOMIZATION_PAGE.TITLE')
        }}
      </h3>
    </div>
    <div class="portal-form">
      <div class="medium-8 columns">
        <div class="form-item">
          <label>
            {{ $t('HELP_CENTER.PORTAL.ADD.THEME_COLOR.LABEL') }}
          </label>
          <woot-color-picker v-model="color" />
          <p class="color-help--text">
            {{ $t('HELP_CENTER.PORTAL.ADD.THEME_COLOR.HELP_TEXT') }}
          </p>
        </div>
        <div class="form-item">
          <woot-input
            v-model.trim="pageTitle"
            :label="$t('HELP_CENTER.PORTAL.ADD.PAGE_TITLE.LABEL')"
            :placeholder="$t('HELP_CENTER.PORTAL.ADD.PAGE_TITLE.PLACEHOLDER')"
            :help-text="$t('HELP_CENTER.PORTAL.ADD.PAGE_TITLE.HELP_TEXT')"
          />
        </div>
        <div class="form-item">
          <woot-input
            v-model.trim="headerText"
            :label="$t('HELP_CENTER.PORTAL.ADD.HEADER_TEXT.LABEL')"
            :placeholder="$t('HELP_CENTER.PORTAL.ADD.HEADER_TEXT.PLACEHOLDER')"
            :help-text="$t('HELP_CENTER.PORTAL.ADD.HEADER_TEXT.HELP_TEXT')"
          />
        </div>
        <div class="form-item">
          <woot-input
            v-model.trim="homePageLink"
            :label="$t('HELP_CENTER.PORTAL.ADD.HOME_PAGE_LINK.LABEL')"
            :placeholder="
              $t('HELP_CENTER.PORTAL.ADD.HOME_PAGE_LINK.PLACEHOLDER')
            "
            :help-text="$t('HELP_CENTER.PORTAL.ADD.HOME_PAGE_LINK.HELP_TEXT')"
          />
        </div>
      </div>
    </div>
    <div class="flex-end">
      <woot-button
        :is-loading="uiFlags.isUpdating"
        @click="updatePortalSettings"
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
import { mapGetters } from 'vuex';

import { getRandomColor } from 'dashboard/helper/labelColor';

import alertMixin from 'shared/mixins/alertMixin';
export default {
  components: {},
  mixins: [alertMixin],
  data() {
    return {
      color: '#000',
      pageTitle: '',
      headerText: '',
      homePageLink: '',
      alertMessage: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'portals/uiFlagsIn',
      portals: 'portals/allPortals',
    }),
    createdPortalSlug() {
      const {
        params: { portalSlug: slug },
      } = this.$route;
      return slug;
    },
    createdPortalId() {
      const { portals } = this;
      const createdPortal = portals.find(
        portal => portal.slug === this.createdPortalSlug
      );
      return createdPortal ? createdPortal.id : null;
    },
  },
  mounted() {
    this.fetchPortals();
    this.color = getRandomColor();
  },
  methods: {
    fetchPortals() {
      this.$store.dispatch('portals/index');
    },
    async updatePortalSettings() {
      try {
        await this.$store.dispatch('portals/update', {
          id: this.createdPortalId,
          slug: this.createdPortalSlug,
          color: this.color,
          page_title: this.pageTitle,
          header_text: this.headerText,
          homepage_link: this.homePageLink,
          config: {
            // TODO: add support for choosing locale
            allowed_locales: ['en'],
          },
        });
        this.alertMessage = this.$t(
          'HELP_CENTER.PORTAL.ADD.API.SUCCESS_MESSAGE_FOR_UPDATE'
        );
      } catch (error) {
        this.alertMessage =
          error?.message ||
          this.$t('HELP_CENTER.PORTAL.ADD.API.ERROR_MESSAGE_FOR_UPDATE');
      } finally {
        this.$router.push({
          name: 'portal_finish',
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
    .color-help--text {
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
  .colorpicker--selected {
    margin-bottom: 0;
  }
}
</style>
