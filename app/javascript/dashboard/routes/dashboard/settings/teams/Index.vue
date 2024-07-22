<template>
  <div class="flex-1 overflow-auto">
    <div class="flex flex-row gap-4 p-8">
      <div class="w-full md:w-3/5">
        <p
          v-if="!teamsList.length"
          class="flex flex-col items-center justify-center h-full"
        >
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
                    <woot-button
                      v-if="isAdmin"
                      v-tooltip.top="$t('TEAMS_SETTINGS.LIST.EDIT_TEAM')"
                      variant="smooth"
                      size="tiny"
                      color-scheme="secondary"
                      class-names="grey-btn"
                      icon="settings"
                    />
                  </router-link>
                  <woot-button
                    v-if="isAdmin"
                    v-tooltip.top="$t('TEAMS_SETTINGS.DELETE.BUTTON_TEXT')"
                    variant="smooth"
                    color-scheme="alert"
                    size="tiny"
                    icon="dismiss-circle"
                    class-names="grey-btn"
                    :is-loading="loading[item.id]"
                    @click="openDelete(item)"
                  />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="hidden w-1/3 md:block">
        <span
          v-dompurify-html="
            $t('TEAMS_SETTINGS.SIDEBAR_TXT', {
              installationName: globalConfig.installationName,
            })
          "
        />
      </div>
    </div>
    <woot-confirm-delete-modal
      v-if="showDeletePopup"
      :show.sync="showDeletePopup"
      :title="confirmDeleteTitle"
      :message="$t('TEAMS_SETTINGS.DELETE.CONFIRM.MESSAGE')"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
      :confirm-value="selectedTeam.name"
      :confirm-place-holder-text="confirmPlaceHolderText"
      @on-confirm="confirmDeletion"
      @on-close="closeDelete"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import accountMixin from '../../../../mixins/account';

export default {
  components: {},
  mixins: [accountMixin],
  setup() {
    const { isAdmin } = useAdmin();
    return {
      isAdmin,
    };
  },
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
    confirmDeleteTitle() {
      return this.$t('TEAMS_SETTINGS.DELETE.CONFIRM.TITLE', {
        teamName: this.selectedTeam.name,
      });
    },
    confirmPlaceHolderText() {
      return `${this.$t('TEAMS_SETTINGS.DELETE.CONFIRM.PLACE_HOLDER', {
        teamName: this.selectedTeam.name,
      })}`;
    },
  },
  methods: {
    async deleteTeam({ id }) {
      try {
        await this.$store.dispatch('teams/delete', id);
        useAlert(this.$t('TEAMS_SETTINGS.DELETE.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('TEAMS_SETTINGS.DELETE.API.ERROR_MESSAGE'));
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
