<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onMounted, ref } from 'vue';
import Avatar from 'next/avatar/Avatar.vue';
import { useI18n } from 'vue-i18n';
import {
  useStoreGetters,
  useStore,
  useMapGetter,
} from 'dashboard/composables/store';

import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import { getHelpUrlForFeature } from 'dashboard/helper/featureHelper';
import AddAgent from './AddAgent.vue';
import EditAgent from './EditAgent.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const loading = ref({});
const showAddPopup = ref(false);
const showDeletePopup = ref(false);
const showEditPopup = ref(false);
const agentAPI = ref({ message: '' });
const currentAgent = ref({});

const helpURL = computed(() => getHelpUrlForFeature('agents'));

const deleteConfirmText = computed(
  () => `${t('AGENT_MGMT.DELETE.CONFIRM.YES')} ${currentAgent.value.name}`
);
const deleteRejectText = computed(() => {
  return `${t('AGENT_MGMT.DELETE.CONFIRM.NO')} ${currentAgent.value.name}`;
});
const deleteMessage = computed(() => {
  return ` ${currentAgent.value.name}?`;
});

const agentList = computed(() => getters['agents/getAgents'].value);
const uiFlags = computed(() => getters['agents/getUIFlags'].value);
const currentUserId = computed(() => getters.getCurrentUserID.value);
const customRoles = useMapGetter('customRole/getCustomRoles');

onMounted(() => {
  store.dispatch('agents/get');
  store.dispatch('customRole/getCustomRole');
});

const findCustomRole = agent =>
  customRoles.value.find(role => role.id === agent.custom_role_id);

const getAgentRoleName = agent => {
  if (!agent.custom_role_id) {
    return t(`AGENT_MGMT.AGENT_TYPES.${agent.role.toUpperCase()}`);
  }
  const customRole = findCustomRole(agent);
  return customRole ? customRole.name : '';
};

const getAgentRolePermissions = agent => {
  if (!agent.custom_role_id) {
    return [];
  }
  const customRole = findCustomRole(agent);
  return customRole?.permissions || [];
};

const verifiedAdministrators = computed(() => {
  return agentList.value.filter(
    agent => agent.role === 'administrator' && agent.confirmed
  );
});

const showEditAction = agent => {
  return currentUserId.value !== agent.id;
};

const showDeleteAction = agent => {
  if (currentUserId.value === agent.id) {
    return false;
  }

  if (!agent.confirmed) {
    return true;
  }

  if (agent.role === 'administrator') {
    return verifiedAdministrators.value.length !== 1;
  }
  return true;
};

const showAlertMessage = message => {
  loading.value[currentAgent.value.id] = false;
  currentAgent.value = {};
  agentAPI.value.message = message;
  useAlert(message);
};

const openAddPopup = () => {
  showAddPopup.value = true;
};
const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = agent => {
  showEditPopup.value = true;
  currentAgent.value = agent;
};
const hideEditPopup = () => {
  showEditPopup.value = false;
};

const openDeletePopup = agent => {
  showDeletePopup.value = true;
  currentAgent.value = agent;
};
const closeDeletePopup = () => {
  showDeletePopup.value = false;
};

const deleteAgent = async id => {
  try {
    await store.dispatch('agents/delete', id);
    showAlertMessage(t('AGENT_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    showAlertMessage(t('AGENT_MGMT.DELETE.API.ERROR_MESSAGE'));
  }
};
const confirmDeletion = () => {
  loading.value[currentAgent.value.id] = true;
  closeDeletePopup();
  deleteAgent(currentAgent.value.id);
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('AGENT_MGMT.LOADING')"
    :no-records-found="!agentList.length"
    :no-records-message="$t('AGENT_MGMT.LIST.404')"
  >
    <template #header>
      <div
        class="flex flex-col gap-6 pb-2 sm:flex-row sm:items-end sm:justify-between"
      >
        <div class="min-w-0 space-y-2">
          <h2 class="mb-0 text-3xl font-bold tracking-tight text-on-surface">
            {{ $t('AGENT_MGMT.HEADER') }}
          </h2>
          <p class="mb-0 max-w-2xl text-base text-on-primary-container">
            {{ $t('AGENT_MGMT.PAGE_SUBTITLE') }}
          </p>
          <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
            <a
              v-if="helpURL"
              :href="helpURL"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1 text-sm font-medium text-secondary hover:underline"
            >
              {{ $t('AGENT_MGMT.LEARN_MORE') }}
              <Icon icon="i-lucide-chevron-right" class="size-4 shrink-0" />
            </a>
          </CustomBrandPolicyWrapper>
        </div>
        <Button
          solid
          teal
          lg
          icon="i-lucide-plus"
          :label="$t('AGENT_MGMT.HEADER_BTN_TXT')"
          class="w-full shrink-0 rounded-xl font-bold shadow-none hover:shadow-[0_0_20px_rgba(4,190,153,0.4)] active:scale-[0.98] sm:w-auto"
          @click="openAddPopup"
        />
      </div>
    </template>
    <template #body>
      <div
        class="overflow-x-auto rounded-2xl border border-outline-variant/10 shadow-xl"
      >
        <div class="min-w-[44rem] bg-surface-container-low">
          <div
            class="grid grid-cols-12 border-b border-surface-container-high/50 bg-surface-container-high/30 px-6 py-4"
          >
            <div
              class="col-span-5 text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
            >
              {{ $t('AGENT_MGMT.LIST.TABLE_HEADER.IDENTITY') }}
            </div>
            <div
              class="col-span-2 text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
            >
              {{ $t('AGENT_MGMT.LIST.TABLE_HEADER.ROLE') }}
            </div>
            <div
              class="col-span-3 text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
            >
              {{ $t('AGENT_MGMT.LIST.TABLE_HEADER.STATUS') }}
            </div>
            <div
              class="col-span-2 text-right text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
            >
              {{ $t('AGENT_MGMT.LIST.TABLE_HEADER.ACTIONS') }}
            </div>
          </div>
          <div class="divide-y divide-surface-container-high/30">
            <div
              v-for="agent in agentList"
              :key="agent.email"
              class="grid grid-cols-12 items-center px-6 py-4 transition-all duration-200 hover:bg-surface-container-high/40"
            >
              <div class="col-span-5 flex min-w-0 items-center gap-4">
                <Avatar
                  :src="agent.thumbnail"
                  :name="agent.name"
                  :status="agent.availability_status"
                  :size="40"
                  hide-offline-status
                />
                <div class="min-w-0">
                  <span
                    class="block break-words text-sm font-bold capitalize text-on-surface"
                  >
                    {{ agent.name }}
                  </span>
                  <span
                    class="block truncate text-xs text-on-primary-container"
                    :title="agent.email"
                  >
                    {{ agent.email }}
                  </span>
                </div>
              </div>

              <div
                class="relative col-span-2 min-w-0 py-1 ltr:pr-2 rtl:pl-2"
                :class="{ group: agent.custom_role_id }"
              >
                <span
                  class="inline-flex max-w-full items-center rounded-md bg-surface-container-high px-2.5 py-1 text-xs font-medium text-tertiary/70"
                  :class="{
                    'cursor-pointer hover:text-tertiary': agent.custom_role_id,
                  }"
                >
                  <span class="truncate">{{ getAgentRoleName(agent) }}</span>
                </span>

                <div
                  v-if="agent.custom_role_id"
                  class="absolute left-0 top-full z-20 mt-1 hidden w-auto max-w-[min(100vw-2rem,300px)] rounded-xl border border-outline-variant/15 bg-surface-container-low p-4 shadow-lg group-hover:block"
                >
                  <div class="flex flex-col gap-1">
                    <span class="font-semibold text-on-surface">
                      {{ $t('AGENT_MGMT.LIST.AVAILABLE_CUSTOM_ROLE') }}
                    </span>
                    <ul class="mb-0 list-disc pl-4">
                      <li
                        v-for="permission in getAgentRolePermissions(agent)"
                        :key="permission"
                        class="font-normal text-on-surface-variant"
                      >
                        {{
                          $t(
                            `CUSTOM_ROLE.PERMISSIONS.${permission.toUpperCase()}`
                          )
                        }}
                      </li>
                    </ul>
                  </div>
                </div>
              </div>

              <div class="col-span-3 min-w-0">
                <div
                  v-if="agent.confirmed"
                  class="flex items-center gap-2 text-secondary"
                >
                  <Icon icon="i-lucide-badge-check" class="size-4 shrink-0" />
                  <span class="text-xs font-semibold">
                    {{ $t('AGENT_MGMT.LIST.VERIFIED') }}
                  </span>
                </div>
                <div v-else class="flex items-center gap-2 text-amber-400/90">
                  <Icon icon="i-lucide-mail-warning" class="size-4 shrink-0" />
                  <span class="text-xs font-medium text-on-primary-container">
                    {{ $t('AGENT_MGMT.LIST.VERIFICATION_PENDING') }}
                  </span>
                </div>
              </div>

              <div class="col-span-2 flex justify-end gap-1">
                <button
                  v-if="showEditAction(agent)"
                  v-tooltip.top="$t('AGENT_MGMT.EDIT.BUTTON_TEXT')"
                  type="button"
                  class="rounded-lg p-2 text-tertiary opacity-70 outline-none transition-all hover:bg-surface-container-high hover:text-secondary hover:opacity-100 focus-visible:ring-2 focus-visible:ring-secondary/40"
                  @click="openEditPopup(agent)"
                >
                  <Icon icon="i-lucide-pen" class="size-5" />
                </button>
                <button
                  v-if="showDeleteAction(agent)"
                  v-tooltip.top="$t('AGENT_MGMT.DELETE.BUTTON_TEXT')"
                  type="button"
                  :disabled="loading[agent.id]"
                  class="rounded-lg p-2 text-tertiary opacity-70 outline-none transition-all hover:bg-surface-container-high hover:text-error hover:opacity-100 focus-visible:ring-2 focus-visible:ring-error/40 disabled:pointer-events-none disabled:opacity-40"
                  @click="openDeletePopup(agent)"
                >
                  <Spinner v-if="loading[agent.id]" class="size-5" />
                  <Icon v-else icon="i-lucide-trash-2" class="size-5" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
      <p class="mt-6 text-xs font-medium text-on-primary-container">
        {{ $t('AGENT_MGMT.LIST.SHOWING_COUNT', { count: agentList.length }) }}
      </p>
    </template>

    <woot-modal v-model:show="showAddPopup" :on-close="hideAddPopup">
      <AddAgent @close="hideAddPopup" />
    </woot-modal>

    <woot-modal v-model:show="showEditPopup" :on-close="hideEditPopup">
      <EditAgent
        v-if="showEditPopup"
        :id="currentAgent.id"
        :name="currentAgent.name"
        :provider="currentAgent.provider"
        :type="currentAgent.role"
        :email="currentAgent.email"
        :availability="currentAgent.availability_status"
        :custom-role-id="currentAgent.custom_role_id"
        @close="hideEditPopup"
      />
    </woot-modal>

    <woot-delete-modal
      v-model:show="showDeletePopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('AGENT_MGMT.DELETE.CONFIRM.TITLE')"
      :message="$t('AGENT_MGMT.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />
  </SettingsLayout>
</template>
