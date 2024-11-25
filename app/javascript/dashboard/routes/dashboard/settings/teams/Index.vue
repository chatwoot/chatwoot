<script setup>
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import { computed, ref } from 'vue';

import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

const store = useStore();
const { t } = useI18n();
const getters = useStoreGetters();
const teamsList = computed(() => getters['teams/getTeams'].value);
const uiFlags = computed(() => getters['teams/getUIFlags'].value);
const { isAdmin } = useAdmin();

const loading = ref({});

const deleteTeam = async ({ id }) => {
  try {
    loading.value[id] = true;
    await store.dispatch('teams/delete', id);
    useAlert(t('TEAMS_SETTINGS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('TEAMS_SETTINGS.DELETE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[id] = false;
  }
};

const showDeletePopup = ref(false);
const selectedTeam = ref({});

const openDelete = team => {
  showDeletePopup.value = true;
  selectedTeam.value = team;
};

const closeDelete = () => {
  showDeletePopup.value = false;
  selectedTeam.value = {};
};

const confirmDeletion = () => {
  deleteTeam(selectedTeam.value);
  closeDelete();
};

const deleteConfirmText = computed(
  () => `${t('TEAMS_SETTINGS.DELETE.CONFIRM.YES')} ${selectedTeam.value.name}`
);

const deleteRejectText = computed(() => t('TEAMS_SETTINGS.DELETE.CONFIRM.NO'));

const confirmDeleteTitle = computed(() =>
  t('TEAMS_SETTINGS.DELETE.CONFIRM.TITLE', {
    teamName: selectedTeam.value.name,
  })
);

const confirmPlaceHolderText = computed(() =>
  t('TEAMS_SETTINGS.DELETE.CONFIRM.PLACE_HOLDER', {
    teamName: selectedTeam.value.name,
  })
);
</script>

<template>
  <div class="flex-1 overflow-auto">
    <BaseSettingsHeader
      :title="$t('TEAMS_SETTINGS.HEADER')"
      :description="$t('TEAMS_SETTINGS.DESCRIPTION')"
      :link-text="$t('TEAMS_SETTINGS.LEARN_MORE')"
      feature-name="team_management"
    >
      <template #actions>
        <router-link
          v-if="isAdmin"
          :to="{ name: 'settings_teams_new' }"
          class="button rounded-md primary"
        >
          <fluent-icon icon="add-circle" />
          <span class="button__content">
            {{ $t('TEAMS_SETTINGS.NEW_TEAM') }}
          </span>
        </router-link>
      </template>
    </BaseSettingsHeader>
    <div class="mt-6 flex-1 text-slate-700 dark:text-slate-300">
      <woot-loading-state
        v-if="uiFlags.isFetching"
        :message="$t('TEAMS_SETTINGS.LOADING')"
      />
      <p
        v-else-if="!teamsList.length"
        class="flex flex-col items-center justify-center h-full text-base p-8"
      >
        {{ $t('TEAMS_SETTINGS.LIST.404') }}
      </p>

      <table
        v-else
        class="min-w-full divide-y divide-slate-75 dark:divide-slate-700"
      >
        <tbody class="divide-y divide-slate-50 dark:divide-slate-800">
          <tr v-for="team in teamsList" :key="team.id">
            <td class="py-4 pr-4">
              <span class="block font-medium capitalize">{{ team.name }}</span>
              <p class="mb-0">{{ team.description }}</p>
            </td>

            <td class="py-4 flex justify-end gap-1">
              <router-link
                :to="{
                  name: 'settings_teams_edit',
                  params: { teamId: team.id },
                }"
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
                :is-loading="loading[team.id]"
                @click="openDelete(team)"
              />
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <woot-confirm-delete-modal
      v-if="showDeletePopup"
      v-model:show="showDeletePopup"
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
