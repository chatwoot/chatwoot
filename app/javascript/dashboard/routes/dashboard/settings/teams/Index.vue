<template>
  <div class="column content-box">
    <!-- List Canned Response -->
    <div class="row">
      <div class="small-8 columns">
        <p v-if="!teamsList.length" class="no-items-error-message">
          {{ $t('TEAMS_SETTINGS.LIST.404') }}
          <router-link
            v-if="isAdmin"
            :to="addAccountScoping('settings/teams/new')"
          >
            {{ $t('TEAMS_SETTINGS.NEW_TEAM') }}
          </router-link>
        </p>

        <table v-if="teamsList.length" class="woot-table">
          <tbody>
            <tr v-for="item in teamsList" :key="item.id">
              <td>
                <span class="agent-name">{{ item.name }}</span>
                <p>{{ item.description }}</p>
              </td>

              <!-- Action Buttons -->
              <td>
                <div class="button-wrapper">
                  <router-link
                    :to="addAccountScoping(`settings/teams/${item.id}`)"
                  >
                    <woot-submit-button
                      v-if="isAdmin"
                      :button-text="$t('TEAMS_SETTINGS.SETTINGS')"
                      icon-class="ion-gear-b"
                      button-class="link hollow grey-btn"
                    />
                  </router-link>

                  <woot-submit-button
                    v-if="isAdmin"
                    :button-text="$t('TEAMS_SETTINGS.DELETE.BUTTON_TEXT')"
                    :loading="loading[item.id]"
                    icon-class="ion-close-circled"
                    button-class="link hollow grey-btn"
                    @click="openDelete(item)"
                  />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="small-4 columns">
        <span
          v-html="
            useInstallationName(
              $t('TEAMS_SETTINGS.SIDEBAR_TXT'),
              globalConfig.installationName
            )
          "
        />
      </div>
    </div>
    <settings
      v-if="showSettings"
      :show.sync="showSettings"
      :on-close="closeSettings"
      :inbox="selectedTeam"
    />

    <woot-delete-modal
      :show.sync="showDeletePopup"
      :on-close="closeDelete"
      :on-confirm="confirmDeletion"
      :title="$t('TEAMS_SETTINGS.DELETE.CONFIRM.TITLE')"
      :message="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import Settings from './Settings';
import adminMixin from '../../../../mixins/isAdmin';
import accountMixin from '../../../../mixins/account';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  components: {
    Settings,
  },
  mixins: [adminMixin, accountMixin, globalConfigMixin],
  data() {
    return {
      loading: {},
      showSettings: false,
      showDeletePopup: false,
      selectedTeam: {},
    };
  },
  computed: {
    ...mapGetters({
      teamsList: 'teams/getTeams',
      globalConfig: 'globalConfig/get',
    }),
    // Delete Modal
    deleteConfirmText() {
      return `${this.$t('TEAMS_SETTINGS.DELETE.CONFIRM.YES')} ${
        this.selectedTeam.name
      }`;
    },
    deleteRejectText() {
      return this.$t('TEAMS_SETTINGS.DELETE.CONFIRM.NO');
    },
    deleteMessage() {
      return `${this.$t('TEAMS_SETTINGS.DELETE.CONFIRM.MESSAGE')} ${
        this.selectedTeam.name
      } ?`;
    },
  },
  methods: {
    openSettings(team) {
      this.showSettings = true;
      this.selectedTeam = team;
    },
    closeSettings() {
      this.showSettings = false;
      this.selectedTeam = {};
    },
    async deleteTeam({ id }) {
      try {
        await this.$store.dispatch('teams/delete', id);
        bus.$emit(
          'newToastMessage',
          this.$t('TEAMS_SETTINGS.DELETE.API.SUCCESS_MESSAGE')
        );
      } catch (error) {
        bus.$emit(
          'newToastMessage',
          this.$t('TEAMS_SETTINGS.DELETE.API.ERROR_MESSAGE')
        );
      }
    },

    confirmDeletion() {
      this.deleteTeam(this.selectedTeam);
      this.closeDelete();
    },
    openDelete(inbox) {
      this.showDeletePopup = true;
      this.selectedTeam = inbox;
    },
    closeDelete() {
      this.showDeletePopup = false;
      this.selectedTeam = {};
    },
  },
};
</script>
<style lang="scss" scoped>
.button-wrapper {
  min-width: unset;
  justify-content: flex-end;
  padding-right: var(--space-large);
}
</style>
