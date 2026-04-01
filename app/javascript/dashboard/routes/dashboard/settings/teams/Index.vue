<script setup>
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { computed, ref } from 'vue';

import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import { getHelpUrlForFeature } from 'dashboard/helper/featureHelper';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import SettingsLayout from '../SettingsLayout.vue';

const store = useStore();
const { t } = useI18n();
const getters = useStoreGetters();
const teamsList = computed(() => getters['teams/getTeams'].value);
const uiFlags = computed(() => getters['teams/getUIFlags'].value);
const { isAdmin } = useAdmin();

const helpURL = computed(() => getHelpUrlForFeature('team_management'));

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
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('TEAMS_SETTINGS.LOADING')"
    :no-records-found="!teamsList.length"
    :no-records-message="$t('TEAMS_SETTINGS.LIST.404')"
  >
    <template #header>
      <div
        class="flex flex-col gap-6 pb-2 sm:flex-row sm:items-end sm:justify-between"
      >
        <div class="min-w-0 space-y-2">
          <h2 class="mb-0 text-3xl font-bold tracking-tight text-on-surface">
            {{ $t('TEAMS_SETTINGS.HEADER') }}
          </h2>
          <p class="mb-0 max-w-2xl text-base text-on-primary-container">
            {{ $t('TEAMS_SETTINGS.PAGE_SUBTITLE') }}
          </p>
          <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
            <a
              v-if="helpURL"
              :href="helpURL"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1 text-sm font-medium text-secondary hover:underline"
            >
              {{ $t('TEAMS_SETTINGS.LEARN_MORE') }}
              <Icon icon="i-lucide-chevron-right" class="size-4 shrink-0" />
            </a>
          </CustomBrandPolicyWrapper>
        </div>
        <router-link
          v-if="isAdmin"
          :to="{ name: 'settings_teams_new' }"
          class="block w-full shrink-0 sm:inline-flex sm:w-auto"
        >
          <Button
            solid
            teal
            lg
            icon="i-lucide-plus"
            :label="$t('TEAMS_SETTINGS.NEW_TEAM')"
            class="w-full rounded-xl font-bold shadow-none hover:shadow-[0_0_20px_rgba(4,190,153,0.4)] active:scale-[0.98] sm:w-auto"
          />
        </router-link>
      </div>
    </template>
    <template #body>
      <div
        class="overflow-x-auto rounded-2xl border border-outline-variant/10 shadow-xl"
      >
        <div class="min-w-[36rem] bg-surface-container-low">
          <div
            class="grid grid-cols-12 border-b border-surface-container-high/50 bg-surface-container-high/30 px-6 py-4"
          >
            <div
              class="col-span-10 text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
            >
              {{ $t('TEAMS_SETTINGS.LIST.TABLE_HEADER.TEAM') }}
            </div>
            <div
              class="col-span-2 text-right text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
            >
              {{ $t('TEAMS_SETTINGS.LIST.TABLE_HEADER.ACTIONS') }}
            </div>
          </div>
          <div class="divide-y divide-surface-container-high/30">
            <div
              v-for="team in teamsList"
              :key="team.id"
              class="grid grid-cols-12 items-center px-6 py-4 transition-all duration-200 hover:bg-surface-container-high/40"
            >
              <div class="col-span-10 min-w-0">
                <span
                  class="block break-words text-sm font-bold capitalize text-on-surface"
                >
                  {{ team.name }}
                </span>
                <p
                  class="mb-0 mt-0.5 line-clamp-2 text-xs text-on-primary-container"
                >
                  {{ team.description }}
                </p>
              </div>
              <div class="col-span-2 flex justify-end gap-1">
                <router-link
                  v-if="isAdmin"
                  v-slot="{ href, navigate }"
                  :to="{
                    name: 'settings_teams_edit',
                    params: { teamId: team.id },
                  }"
                  custom
                >
                  <a
                    v-tooltip.top="$t('TEAMS_SETTINGS.LIST.EDIT_TEAM')"
                    :href="href"
                    class="inline-flex rounded-lg p-2 text-tertiary opacity-70 outline-none transition-all hover:bg-surface-container-high hover:text-secondary hover:opacity-100 focus-visible:ring-2 focus-visible:ring-secondary/40"
                    @click="navigate"
                  >
                    <Icon icon="i-lucide-settings" class="size-5" />
                  </a>
                </router-link>
                <button
                  v-if="isAdmin"
                  v-tooltip.top="$t('TEAMS_SETTINGS.DELETE.BUTTON_TEXT')"
                  type="button"
                  :disabled="loading[team.id]"
                  class="rounded-lg p-2 text-tertiary opacity-70 outline-none transition-all hover:bg-surface-container-high hover:text-error hover:opacity-100 focus-visible:ring-2 focus-visible:ring-error/40 disabled:pointer-events-none disabled:opacity-40"
                  @click="openDelete(team)"
                >
                  <Spinner v-if="loading[team.id]" class="size-5" />
                  <Icon v-else icon="i-lucide-trash-2" class="size-5" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
      <p class="mt-6 text-xs font-medium text-on-primary-container">
        {{
          $t('TEAMS_SETTINGS.LIST.SHOWING_COUNT', { count: teamsList.length })
        }}
      </p>
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
