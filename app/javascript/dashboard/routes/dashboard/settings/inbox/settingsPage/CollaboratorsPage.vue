<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import SettingsSection from '../../../../../components/SettingsSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import assignmentPoliciesAPI from 'dashboard/api/assignmentPolicies';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  inbox: {
    type: Object,
    default: () => ({}),
  },
});

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const selectedAgents = ref([]);
const isAgentListUpdating = ref(false);
const enableAutoAssignment = ref(false);
const assignmentPolicy = ref(null);
const isLoadingPolicy = ref(false);
const isDeletingPolicy = ref(false);
const showDeleteConfirmModal = ref(false);

const agentList = computed(() => store.getters['agents/getAgents']);

const isFeatureEnabled = feature => {
  const accountId = Number(route.params.accountId);
  return store.getters['accounts/isFeatureEnabledonAccount'](
    accountId,
    feature
  );
};

const hasAdvancedAssignment = computed(() => {
  return isFeatureEnabled('advanced_assignment');
});

const hasAssignmentV2 = computed(() => {
  return isFeatureEnabled('assignment_v2');
});

const showAdvancedAssignmentUI = computed(() => {
  return hasAdvancedAssignment.value && hasAssignmentV2.value;
});

const assignmentOrderLabel = computed(() => {
  if (!assignmentPolicy.value) return '';
  const priority = assignmentPolicy.value.conversation_priority;
  if (priority === 'earliest_created') {
    return t('INBOX_MGMT.ASSIGNMENT.PRIORITY.EARLIEST_CREATED');
  }
  if (priority === 'longest_waiting') {
    return t('INBOX_MGMT.ASSIGNMENT.PRIORITY.LONGEST_WAITING');
  }
  return priority;
});

const assignmentMethodLabel = computed(() => {
  if (!assignmentPolicy.value) return '';
  const order = assignmentPolicy.value.assignment_order;
  if (order === 'round_robin') {
    return t('INBOX_MGMT.ASSIGNMENT.METHOD.ROUND_ROBIN');
  }
  if (order === 'balanced') {
    return t('INBOX_MGMT.ASSIGNMENT.METHOD.BALANCED');
  }
  return order;
});

const fetchAttachedAgents = async () => {
  try {
    const response = await store.dispatch('inboxMembers/get', {
      inboxId: props.inbox.id,
    });
    const {
      data: { payload: inboxMembers },
    } = response;
    selectedAgents.value = inboxMembers;
  } catch (error) {
    //  Handle error
  }
};

const fetchAssignmentPolicy = async () => {
  if (!props.inbox.id) return;

  isLoadingPolicy.value = true;
  try {
    const response = await assignmentPoliciesAPI.getInboxPolicy(props.inbox.id);
    assignmentPolicy.value = response.data;
  } catch (error) {
    // No policy attached, which is fine
    assignmentPolicy.value = null;
  } finally {
    isLoadingPolicy.value = false;
  }
};

const handleToggleAutoAssignment = async () => {
  try {
    const payload = {
      id: props.inbox.id,
      formData: false,
      enable_auto_assignment: enableAutoAssignment.value,
    };
    await store.dispatch('inboxes/updateInbox', payload);
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
  }
};

const updateAgents = async () => {
  const agentListIds = selectedAgents.value.map(el => el.id);
  isAgentListUpdating.value = true;
  try {
    await store.dispatch('inboxMembers/create', {
      inboxId: props.inbox.id,
      agentList: agentListIds,
    });
    useAlert(t('AGENT_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('AGENT_MGMT.EDIT.API.ERROR_MESSAGE'));
  }
  isAgentListUpdating.value = false;
};

const navigateToAssignmentPolicies = () => {
  const accountId = route.params.accountId;
  router.push({
    name: 'agent_assignment_policy_index',
    params: { accountId },
  });
};

const navigateToAssignmentPolicyEdit = () => {
  if (!assignmentPolicy.value?.id) return;
  const accountId = route.params.accountId;
  router.push({
    name: 'agent_assignment_policy_edit',
    params: { accountId, id: assignmentPolicy.value.id },
  });
};

const navigateToBilling = () => {
  const accountId = route.params.accountId;
  router.push({
    name: 'billing_settings_index',
    params: { accountId },
  });
};

const confirmDeletePolicy = () => {
  showDeleteConfirmModal.value = true;
};

const cancelDeletePolicy = () => {
  showDeleteConfirmModal.value = false;
};

const deleteAssignmentPolicy = async () => {
  if (isDeletingPolicy.value) return;
  isDeletingPolicy.value = true;
  try {
    await assignmentPoliciesAPI.removeInboxPolicy(props.inbox.id);
    assignmentPolicy.value = null;
    showDeleteConfirmModal.value = false;
    useAlert(t('INBOX_MGMT.ASSIGNMENT_POLICY.DELETE_SUCCESS'));
  } catch (error) {
    useAlert(t('INBOX_MGMT.ASSIGNMENT_POLICY.DELETE_ERROR'));
  } finally {
    isDeletingPolicy.value = false;
  }
};

const setDefaults = () => {
  enableAutoAssignment.value = props.inbox.enable_auto_assignment;
  fetchAttachedAgents();
  if (showAdvancedAssignmentUI.value) {
    fetchAssignmentPolicy();
  }
};

watch(() => props.inbox, setDefaults, { deep: true });

onMounted(() => {
  setDefaults();
});
</script>

<template>
  <div>
    <SettingsSection
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS_SUB_TEXT')"
    >
      <multiselect
        v-model="selectedAgents"
        :options="agentList"
        track-by="id"
        label="name"
        multiple
        :close-on-select="false"
        :clear-on-select="false"
        hide-selected
        placeholder="Pick some"
        selected-label
        :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
        :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
      />

      <NextButton
        :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
        :is-loading="isAgentListUpdating"
        @click="updateAgents"
      />
    </SettingsSection>

    <SettingsSection
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.AGENT_ASSIGNMENT')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.AGENT_ASSIGNMENT_SUB_TEXT')"
    >
      <!-- New UI for assignment_v2 -->
      <template v-if="hasAssignmentV2">
        <div class="flex items-center justify-between mb-6">
          <h3 class="text-base font-medium text-n-slate-12">
            {{ $t('INBOX_MGMT.ASSIGNMENT.TITLE') }}
          </h3>
          <Switch
            v-model="enableAutoAssignment"
            @change="handleToggleAutoAssignment"
          />
        </div>

        <p class="text-sm text-n-slate-11 mb-6">
          {{ $t('INBOX_MGMT.ASSIGNMENT.DESCRIPTION') }}
        </p>

        <div v-if="enableAutoAssignment" class="mt-4">
          <!-- Policy Card - When policy is attached -->
          <div
            v-if="showAdvancedAssignmentUI && assignmentPolicy"
            class="relative p-6 rounded-xl border border-dashed border-n-weak"
          >
            <button
              type="button"
              class="absolute top-4 right-4 p-2 text-n-slate-10 hover:text-n-ruby-11 hover:bg-n-ruby-3 dark:hover:bg-n-ruby-4 rounded-lg transition-colors"
              @click="confirmDeletePolicy"
            >
              <i class="i-lucide-trash-2 text-base" />
            </button>

            <div class="flex items-start gap-4">
              <div
                class="flex-shrink-0 w-12 h-12 rounded-xl bg-n-slate-3 dark:bg-n-slate-4 flex items-center justify-center"
              >
                <i class="i-lucide-zap text-xl text-n-slate-11" />
              </div>
              <div class="flex-grow pr-10">
                <div class="flex items-center gap-2 mb-1">
                  <h4 class="text-base font-medium text-n-slate-12">
                    {{ assignmentPolicy.name }}
                  </h4>
                </div>
                <p class="text-sm text-n-slate-11 mb-4">
                  {{ $t('INBOX_MGMT.ASSIGNMENT.POLICY_LABEL') }}
                </p>

                <ul class="space-y-2 mb-6">
                  <li class="flex items-center gap-2">
                    <span
                      class="w-1.5 h-1.5 rounded-full bg-n-slate-11 flex-shrink-0"
                    />
                    <span class="text-sm font-medium text-n-slate-12">
                      {{ assignmentOrderLabel }}
                    </span>
                  </li>
                  <li class="flex items-center gap-2">
                    <span
                      class="w-1.5 h-1.5 rounded-full bg-n-slate-11 flex-shrink-0"
                    />
                    <span class="text-sm font-medium text-n-slate-12">
                      {{ assignmentMethodLabel }}
                    </span>
                  </li>
                </ul>

                <div class="pt-4 border-t border-n-weak">
                  <button
                    type="button"
                    class="inline-flex items-center gap-1.5 text-sm font-medium text-n-blue-11 dark:text-n-blue-10 hover:text-n-blue-12 dark:hover:text-n-blue-9 transition-colors"
                    @click="navigateToAssignmentPolicyEdit"
                  >
                    {{ $t('INBOX_MGMT.ASSIGNMENT.CUSTOMIZE_POLICY') }}
                    <i class="i-lucide-arrow-right text-sm" />
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Default Rules Card - When no policy attached but feature enabled -->
          <div
            v-else-if="
              showAdvancedAssignmentUI && !assignmentPolicy && !isLoadingPolicy
            "
            class="p-6 rounded-xl border border-dashed border-n-weak"
          >
            <div class="flex items-start gap-4">
              <div
                class="flex-shrink-0 w-12 h-12 rounded-xl bg-n-slate-3 dark:bg-n-slate-4 flex items-center justify-center"
              >
                <i class="i-lucide-zap text-xl text-n-slate-11" />
              </div>
              <div class="flex-grow">
                <h4 class="text-base font-medium text-n-slate-12 mb-1">
                  {{ $t('INBOX_MGMT.ASSIGNMENT.DEFAULT_RULES_TITLE') }}
                </h4>
                <p class="text-sm text-n-slate-11 mb-4">
                  {{ $t('INBOX_MGMT.ASSIGNMENT.DEFAULT_RULES_DESCRIPTION') }}
                </p>

                <ul class="space-y-2 mb-6">
                  <li class="flex items-center gap-2">
                    <span
                      class="w-1.5 h-1.5 rounded-full bg-n-slate-11 flex-shrink-0"
                    />
                    <span class="text-sm font-medium text-n-slate-12">
                      {{ $t('INBOX_MGMT.ASSIGNMENT.DEFAULT_RULE_1') }}
                    </span>
                  </li>
                  <li class="flex items-center gap-2">
                    <span
                      class="w-1.5 h-1.5 rounded-full bg-n-slate-11 flex-shrink-0"
                    />
                    <span class="text-sm font-medium text-n-slate-12">
                      {{ $t('INBOX_MGMT.ASSIGNMENT.DEFAULT_RULE_2') }}
                    </span>
                  </li>
                </ul>

                <div class="pt-4 border-t border-n-weak">
                  <button
                    type="button"
                    class="inline-flex items-center gap-1.5 text-sm font-medium text-n-blue-11 dark:text-n-blue-10 hover:text-n-blue-12 dark:hover:text-n-blue-9 transition-colors"
                    @click="navigateToAssignmentPolicies"
                  >
                    {{ $t('INBOX_MGMT.ASSIGNMENT.CUSTOMIZE_WITH_POLICY') }}
                    <i class="i-lucide-arrow-right text-sm" />
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Default Rules Card - Feature not enabled (no advanced_assignment) -->
          <div
            v-else-if="!showAdvancedAssignmentUI"
            class="p-6 rounded-xl border border-dashed border-n-weak"
          >
            <div class="flex items-start gap-4">
              <div
                class="flex-shrink-0 w-12 h-12 rounded-xl bg-n-slate-3 dark:bg-n-slate-4 flex items-center justify-center"
              >
                <i class="i-lucide-zap text-xl text-n-slate-11" />
              </div>
              <div class="flex-grow">
                <h4 class="text-base font-medium text-n-slate-12 mb-1">
                  {{ $t('INBOX_MGMT.ASSIGNMENT.DEFAULT_RULES_TITLE') }}
                </h4>
                <p class="text-sm text-n-slate-11 mb-4">
                  {{ $t('INBOX_MGMT.ASSIGNMENT.DEFAULT_RULES_DESCRIPTION') }}
                </p>

                <ul class="space-y-2 mb-6">
                  <li class="flex items-center gap-2">
                    <span
                      class="w-1.5 h-1.5 rounded-full bg-n-slate-11 flex-shrink-0"
                    />
                    <span class="text-sm font-medium text-n-slate-12">
                      {{ $t('INBOX_MGMT.ASSIGNMENT.DEFAULT_RULE_1') }}
                    </span>
                  </li>
                  <li class="flex items-center gap-2">
                    <span
                      class="w-1.5 h-1.5 rounded-full bg-n-slate-11 flex-shrink-0"
                    />
                    <span class="text-sm font-medium text-n-slate-12">
                      {{ $t('INBOX_MGMT.ASSIGNMENT.DEFAULT_RULE_2') }}
                    </span>
                  </li>
                </ul>

                <!-- Upgrade prompt when advanced_assignment is not enabled -->
                <div
                  v-if="!hasAdvancedAssignment"
                  class="pt-4 border-t border-n-weak"
                >
                  <p class="text-sm text-n-slate-11 mb-2">
                    {{ $t('INBOX_MGMT.ASSIGNMENT.UPGRADE_PROMPT') }}
                  </p>
                  <button
                    type="button"
                    class="inline-flex items-center gap-1.5 text-sm font-medium text-n-blue-11 dark:text-n-blue-10 hover:text-n-blue-12 dark:hover:text-n-blue-9 transition-colors"
                    @click="navigateToBilling"
                  >
                    {{ $t('INBOX_MGMT.ASSIGNMENT.UPGRADE_TO_BUSINESS') }}
                    <i class="i-lucide-arrow-right text-sm" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </template>

      <!-- Old UI for non-assignment_v2 -->
      <template v-else>
        <label class="w-3/4 settings-item">
          <div class="flex items-center gap-2">
            <input
              id="enableAutoAssignment"
              v-model="enableAutoAssignment"
              type="checkbox"
              class="flex-shrink-0 mt-0.5 border-n-strong border bg-n-slate-2 checked:border-none checked:bg-n-brand shadow-sm appearance-none rounded-[4px] w-4 h-4 focus:ring-1 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center after:text-center after:text-xs after:font-bold after:relative"
              @change="handleToggleAutoAssignment"
            />
            <label for="enableAutoAssignment">
              {{ $t('INBOX_MGMT.SETTINGS_POPUP.AUTO_ASSIGNMENT') }}
            </label>
          </div>

          <p class="pb-1 text-sm not-italic text-n-slate-11">
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.AUTO_ASSIGNMENT_SUB_TEXT') }}
          </p>
        </label>
      </template>
    </SettingsSection>

    <!-- Delete Confirmation Modal -->
    <woot-modal
      v-if="showDeleteConfirmModal"
      :show="showDeleteConfirmModal"
      :on-close="cancelDeletePolicy"
    >
      <div class="p-6">
        <div class="flex items-center gap-3 mb-4">
          <div
            class="w-10 h-10 rounded-full bg-n-ruby-3 dark:bg-n-ruby-4 flex items-center justify-center"
          >
            <i class="i-lucide-alert-triangle text-ruby-9 text-lg" />
          </div>
          <h3 class="text-lg font-medium text-n-slate-12">
            {{ $t('INBOX_MGMT.ASSIGNMENT_POLICY.DELETE_CONFIRM_TITLE') }}
          </h3>
        </div>
        <p class="text-sm text-n-slate-11 mb-6 ml-13">
          {{ $t('INBOX_MGMT.ASSIGNMENT_POLICY.DELETE_CONFIRM_MESSAGE') }}
        </p>
        <div class="flex justify-end gap-2">
          <NextButton
            color="slate"
            :label="$t('INBOX_MGMT.ASSIGNMENT_POLICY.CANCEL')"
            @click="cancelDeletePolicy"
          />
          <NextButton
            color="ruby"
            :label="$t('INBOX_MGMT.ASSIGNMENT_POLICY.CONFIRM_DELETE')"
            :is-loading="isDeletingPolicy"
            @click="deleteAssignmentPolicy"
          />
        </div>
      </div>
    </woot-modal>
  </div>
</template>
