<template>
  <div class="wizard-body small-9 columns">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.DESC')"
    />
    <woot-loading-state
      v-if="isCreating"
      message="Creating Website Support Channel"
    >
    </woot-loading-state>
    <form v-if="!isCreating" class="row" @submit.prevent="createChannel()">
      <div class="medium-12 columns">
        <label>
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_NAME.LABEL') }}
          <input
            v-model.trim="websiteName"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_NAME.PLACEHOLDER')
            "
          />
        </label>
      </div>
      <div class="medium-12 columns">
        <label>
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_DOMAIN.LABEL') }}
          <input
            v-model.trim="websiteUrl"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_DOMAIN.PLACEHOLDER')
            "
          />
        </label>
      </div>

      <div class="medium-12 columns">
        <label>
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.WIDGET_COLOR.LABEL') }}
          <compact v-model="widgetColor" class="widget-color--selector" />
        </label>
      </div>

      <div class="modal-footer">
        <div class="medium-12 columns">
          <woot-submit-button
            :disabled="!websiteUrl || !websiteName"
            :button-text="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.SUBMIT_BUTTON')"
          />
        </div>
      </div>
    </form>
  </div>
</template>

<script>
import { Compact } from 'vue-color';
import { mapGetters } from 'vuex';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader';

export default {
  components: {
    PageHeader,
    Compact,
  },
  data() {
    return {
      websiteName: '',
      websiteUrl: '',
      widgetColor: { hex: '#009CE0' },
      isCreating: false,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  methods: {
    async createChannel() {
      const website = await this.$store.dispatch(
        'inboxes/createWebsiteChannel',
        {
          website: {
            website_name: this.websiteName,
            website_url: this.websiteUrl,
            widget_color: this.widgetColor.hex,
          },
        }
      );
      router.replace({
        name: 'settings_inboxes_add_agents',
        params: {
          page: 'new',
          inbox_id: website.id,
        },
      });
    },
  },
};
</script>
