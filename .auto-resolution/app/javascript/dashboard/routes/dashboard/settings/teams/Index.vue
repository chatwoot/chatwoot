<script setup>
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import { computed, ref } from 'vue';
import { picoSearch } from '@scmmishra/pico-search';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const store = useStore();
const { t } = useI18n();
const getters = useStoreGetters();
const { isAdmin } = useAdmin();

const loading = ref({});
const searchQuery = ref('');

const teamsList = useMapGetter('teams/getTeams');

const filteredTeamsList = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return teamsList.value;
  return picoSearch(teamsList.value, query, ['name', 'description']);
});

const uiFlags = computed(() => getters['teams/getUIFlags'].value);

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
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('TEAMS_SETTINGS.LOADING')"
    :no-records-found="!teamsList.length"
    :no-records-message="$t('TEAMS_SETTINGS.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('TEAMS_SETTINGS.HEADER')"
        :description="$t('TEAMS_SETTINGS.DESCRIPTION')"
        :link-text="$t('TEAMS_SETTINGS.LEARN_MORE')"
        :search-placeholder="$t('TEAMS_SETTINGS.SEARCH_PLACEHOLDER')"
        feature-name="team_management"
      >
        <template v-if="teamsList?.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{ $t('TEAMS_SETTINGS.COUNT', { n: teamsList.length }) }}
          </span>
        </template>
        <template #actions>
          <router-link v-if="isAdmin" :to="{ name: 'settings_teams_new' }">
            <Button :label="$t('TEAMS_SETTINGS.NEW_TEAM')" size="sm" />
          </router-link>
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <span
        v-if="!filteredTeamsList.length && searchQuery"
        class="flex-1 flex items-center justify-center py-20 text-center text-body-main !text-base text-n-slate-11"
      >
        {{ $t('TEAMS_SETTINGS.NO_RESULTS') }}
      </span>

      <div v-else class="divide-y divide-n-weak border-t border-n-weak">
        <div
          v-for="team in filteredTeamsList"
          :key="team.id"
          class="flex justify-between flex-row items-start gap-4 py-4"
        >
          <div class="flex items-start gap-4">
            <div
              class="flex items-center flex-shrink-0 size-10 justify-center rounded-xl outline outline-1 outline-n-weak -outline-offset-1"
            >
              <Icon
                icon="i-lucide-users-round"
                class="size-4 text-n-slate-11"
              />
            </div>
            <div class="flex flex-col items-start gap-1">
              <span class="block text-heading-3 text-n-slate-12 capitalize">
                {{ team.name }}
              </span>
              <p class="mb-0 text-n-slate-11 text-body-main">
                {{ team.description }}
              </p>
            </div>
          </div>
          <div class="flex justify-end gap-3">
            <router-link
              :to="{
                name: 'settings_teams_edit',
                params: { teamId: team.id },
              }"
            >
              <Button
                v-if="isAdmin"
                v-tooltip.top="$t('TEAMS_SETTINGS.LIST.EDIT_TEAM')"
                icon="i-woot-settings"
                slate
                sm
              />
            </router-link>

            <Button
              v-if="isAdmin"
              v-tooltip.top="$t('TEAMS_SETTINGS.DELETE.BUTTON_TEXT')"
              icon="i-woot-bin"
              slate
              sm
              class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
              :is-loading="loading[team.id]"
              @click="openDelete(team)"
            />
          </div>
        </div>
      </div>
    </template>
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
  </SettingsLayout>
</template>
