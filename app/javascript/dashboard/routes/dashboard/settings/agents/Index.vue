<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onMounted, ref } from 'vue';
import Avatar from 'next/avatar/Avatar.vue';
import { useI18n } from 'vue-i18n';
import { picoSearch } from '@scmmishra/pico-search';
import {
  useStoreGetters,
  useStore,
  useMapGetter,
} from 'dashboard/composables/store';

import AddAgent from './AddAgent.vue';
import EditAgent from './EditAgent.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const loading = ref({});
const showAddPopup = ref(false);
const showDeletePopup = ref(false);
const showEditPopup = ref(false);
const agentAPI = ref({ message: '' });
const currentAgent = ref({});
const searchQuery = ref('');

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

const filteredAgentList = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return agentList.value;
  return picoSearch(agentList.value, query, ['name', 'email']);
});

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
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('AGENT_MGMT.HEADER')"
        :description="$t('AGENT_MGMT.DESCRIPTION')"
        :link-text="$t('AGENT_MGMT.LEARN_MORE')"
        :search-placeholder="$t('AGENT_MGMT.SEARCH_PLACEHOLDER')"
        feature-name="agents"
      >
        <template v-if="agentList?.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{ $t('AGENT_MGMT.COUNT', { n: agentList.length }) }}
          </span>
        </template>
        <template #actions>
          <Button
            :label="$t('AGENT_MGMT.HEADER_BTN_TXT')"
            size="sm"
            @click="openAddPopup"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <span
        v-if="!filteredAgentList.length && searchQuery"
        class="flex-1 flex items-center justify-center py-20 text-center text-body-main !text-base text-n-slate-11"
      >
        {{ $t('AGENT_MGMT.NO_RESULTS') }}
      </span>
      <div v-else class="divide-y divide-n-weak border-t border-n-weak">
        <div
          v-for="(agent, index) in filteredAgentList"
          :key="agent.email"
          class="flex justify-between flex-row items-start gap-4 py-4"
        >
          <div class="flex items-center gap-4">
            <Avatar
              :src="agent.thumbnail"
              :name="agent.name"
              :status="agent.availability_status"
              :size="40"
              hide-offline-status
            />
            <div class="flex flex-col gap-1.5 items-start">
              <span class="block text-heading-3 text-n-slate-12 capitalize">
                {{ agent.name }}
              </span>
              <div class="flex items-center gap-2">
                <span class="text-body-main text-n-slate-11">
                  {{ agent.email }}
                </span>
                <div class="w-px h-3 bg-n-strong rounded-lg" />
                <span
                  class="block w-fit text-body-main text-n-slate-11 relative"
                  :class="{
                    'hover:text-n-slate-12 group cursor-pointer':
                      agent.custom_role_id,
                  }"
                >
                  {{ getAgentRoleName(agent) }}

                  <div
                    class="absolute ltr:left-0 rtl:right-0 z-10 hidden w-[300px] bg-n-alpha-3 backdrop-blur-[100px] rounded-xl outline outline-1 outline-n-container shadow-lg top-14 md:top-12"
                    :class="{ 'group-hover:block': agent.custom_role_id }"
                  >
                    <div class="flex flex-col gap-1 p-4">
                      <span class="text-heading-3 text-n-slate-12">
                        {{ $t('AGENT_MGMT.LIST.AVAILABLE_CUSTOM_ROLE') }}
                      </span>
                      <ul class="ltr:pl-4 rtl:pr-4 mb-0 list-disc">
                        <li
                          v-for="permission in getAgentRolePermissions(agent)"
                          :key="permission"
                          class="text-body-main text-n-slate-11"
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
                </span>
                <div class="w-px h-3 bg-n-strong rounded-lg" />
                <span
                  v-if="agent.confirmed"
                  class="text-body-main text-n-slate-11"
                >
                  {{ $t('AGENT_MGMT.LIST.VERIFIED') }}
                </span>
                <span
                  v-if="!agent.confirmed"
                  class="text-body-main text-n-slate-11"
                >
                  {{ $t('AGENT_MGMT.LIST.VERIFICATION_PENDING') }}
                </span>
              </div>
            </div>
          </div>
          <div class="flex justify-end gap-3">
            <Button
              v-if="showEditAction(agent)"
              v-tooltip.top="$t('AGENT_MGMT.EDIT.BUTTON_TEXT')"
              icon="i-woot-edit-pen"
              slate
              sm
              @click="openEditPopup(agent)"
            />
            <Button
              v-if="showDeleteAction(agent)"
              v-tooltip.top="$t('AGENT_MGMT.DELETE.BUTTON_TEXT')"
              icon="i-woot-bin"
              slate
              sm
              :is-loading="loading[agent.id]"
              @click="openDeletePopup(agent, index)"
            />
          </div>
        </div>
      </div>
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
