<template>
  <div class="column content-box">
    <div class="row">
      <div class="small-8 columns integrations-wrap">
        <div class="row integrations">
          <div v-if="integrationLoaded" class="small-12 columns integration">
            <div class="row">
              <div class="integration--image">
                <img
                  :src="`/assets/dashboard/integrations/${integration.logo}`"
                />
              </div>
              <div class="column">
                <h3 class="integration--title">
                  {{ integration.name }}
                </h3>
                <p class="integration--description">
                  {{ integration.description }}
                </p>
              </div>
              <div class="small-2 column button-wrap">
                <div v-if="integration.enabled">
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
                <div v-if="!integration.enabled">
                  <a :href="integration.action" class="button success nice">
                    {{ $t('INTEGRATION_SETTINGS.CONNECT.BUTTON_TEXT') }}
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
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
/* global bus */
import { mapGetters } from 'vuex';
import { frontendURL } from '../../../../helper/URLHelper';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  mixins: [globalConfigMixin],
  props: ['integrationId', 'code'],
  data() {
    return {
      showDeleteConfirmationPopup: false,
      integrationLoaded: false,
    };
  },
  computed: {
    integration() {
      return this.$store.getters['integrations/getIntegration'](
        this.integrationId
      );
    },
    ...mapGetters({
      currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
      accountId: 'getCurrentAccountId',
    }),
  },
  mounted() {
    this.intializeSlackIntegration();
  },
  methods: {
    frontendURL,
    showAlert(message) {
      bus.$emit('newToastMessage', message);
    },
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
    async intializeSlackIntegration() {
      await this.$store.dispatch('integrations/get', this.integrationId);
      if (this.code) {
        await this.$store.dispatch('integrations/connectSlack', this.code);
        // we are clearing code from the path as subsequent request would throw error
        this.$router.replace(this.$route.path);
      }
      this.integrationLoaded = true;
    },
  },
};
</script>
