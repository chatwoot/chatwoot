<template>
  <div class="column content-box">
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

              <td>
                <div class="button-wrapper">
                  <router-link
                    :to="addAccountScoping(`settings/teams/${item.id}/edit`)"
                  >
                    <woot-submit-button
                      v-if="isAdmin"
                      :button-text="$t('TEAMS_SETTINGS.LIST.EDIT_TEAM')"
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
            $t('TEAMS_SETTINGS.SIDEBAR_TXT', {
              installationName: globalConfig.installationName,
            })
          "
        />
      </div>
    </div>

    <woot-delete-modal
      :show.sync="showDeletePopup"
      :on-close="closeDelete"
      :on-confirm="confirmDeletion"
      :title="deleteTitle"
      :message="$t('TEAMS_SETTINGS.DELETE.CONFIRM.MESSAGE')"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import adminMixin from '../../../../mixins/isAdmin';
import accountMixin from '../../../../mixins/account';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {},
  mixins: [adminMixin, accountMixin, alertMixin],
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
    deleteConfirmText() {
      return `${this.$t('TEAMS_SETTINGS.DELETE.CONFIRM.YES')} ${
        this.selectedTeam.name
      }`;
    },
    deleteRejectText() {
      return this.$t('TEAMS_SETTINGS.DELETE.CONFIRM.NO');
    },
    deleteTitle() {
      return this.$t('TEAMS_SETTINGS.DELETE.CONFIRM.TITLE', {
        teamName: this.selectedTeam.name,
      });
    },
  },
  methods: {
    async deleteTeam({ id }) {
      try {
        await this.$store.dispatch('teams/delete', id);
        this.showAlert(this.$t('TEAMS_SETTINGS.DELETE.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('TEAMS_SETTINGS.DELETE.API.ERROR_MESSAGE'));
      }
    },

    confirmDeletion() {
      this.deleteTeam(this.selectedTeam);
      this.closeDelete();
    },
    openDelete(team) {
      this.showDeletePopup = true;
      this.selectedTeam = team;
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
