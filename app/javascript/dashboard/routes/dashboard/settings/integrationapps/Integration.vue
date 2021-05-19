<template>
  <div class="row">
    <div class="integration--image">
      <img :src="'/dashboard/images/integrations/' + integrationLogo" />
    </div>
    <div class="column">
      <h3 class="integration--title">
        {{ integrationName }}
      </h3>
      <p class="integration--description">
        {{ integrationDescription }}
      </p>
    </div>
    <div class="small-2 column button-wrap">
      <Label :title="labelText" :color-scheme="labelColor" />
    </div>
    <div class="small-2 column button-wrap">
      <router-link
        :to="
          frontendURL(
            `accounts/${accountId}/settings/applications/` + integrationId
          )
        "
      >
        <div v-if="!integrationEnabled">
          <div v-if="integrationAction === 'disconnect'">
            <div @click="openDeletePopup()">
              <woot-submit-button
                :button-text="
                  $t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.BUTTON_TEXT')
                "
                icon-class="ion-close-circled"
                button-class="nice alert"
              />
            </div>
          </div>

          <div>
            <button class="button nice">
              {{ $t('INTEGRATION_SETTINGS.WEBHOOK.CONFIGURE') }}
            </button>
          </div>
        </div>
      </router-link>
    </div>
    <woot-delete-modal
      :show.sync="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.TITLE')"
      :message="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.MESSAGE')"
      :confirm-text="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.YES')"
      :reject-text="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.NO')"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { frontendURL } from '../../../../helper/URLHelper';
import alertMixin from 'shared/mixins/alertMixin';
import Label from 'dashboard/components/ui/Label';

export default {
  components: {
    Label,
  },
  mixins: [alertMixin],
  props: [
    'integrationId',
    'integrationLogo',
    'integrationName',
    'integrationDescription',
    'integrationEnabled',
    'integrationAction',
  ],
  data() {
    return {
      showDeleteConfirmationPopup: false,
    };
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      accountId: 'getCurrentAccountId',
    }),
    labelText() {
      return this.integrationEnabled
        ? this.$t('CAMPAIGN.LIST.STATUS.ENABLED')
        : this.$t('CAMPAIGN.LIST.STATUS.DISABLED');
    },
    labelColor() {
      return this.integrationEnabled ? 'success' : 'secondary';
    },
  },
  methods: {
    frontendURL,
    openDeletePopup() {
      this.showDeleteConfirmationPopup = true;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    confirmDeletion() {
      this.closeDeletePopup();
      this.deleteIntegration(this.deleteIntegration);
      this.$router.push({ name: 'settings_integrations' });
    },
    async deleteIntegration() {
      try {
        await this.$store.dispatch(
          'integrations/deleteIntegration',
          this.integrationId
        );
        this.showAlert(
          this.$t('INTEGRATION_SETTINGS.DELETE.API.SUCCESS_MESSAGE')
        );
      } catch (error) {
        this.showAlert(
          this.$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>
