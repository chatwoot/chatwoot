<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { vOnClickOutside } from '@vueuse/components';
import { useVuelidate } from '@vuelidate/core';
import { minValue } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { useConfig } from 'dashboard/composables/useConfig';
import SettingsSection from '../../../../../components/SettingsSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
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
const { isEnterprise } = useConfig();

const selectedAgents = ref([]);
const isAgentListUpdating = ref(false);
const enableAutoAssignment = ref(false);
const maxAssignmentLimit = ref(null);
const assignmentPolicy = ref(null);
const isLoadingPolicy = ref(false);
const isDeletingPolicy = ref(false);
const showDeleteConfirmModal = ref(false);
const availablePolicies = ref([]);
const isLoadingPolicies = ref(false);
const showPolicyDropdown = ref(false);
const isLinkingPolicy = ref(false);

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

// Vuelidate validation rules
const rules = {
  maxAssignmentLimit: {
    minValue: minValue(1),
  },
};

const v$ = useVuelidate(rules, { maxAssignmentLimit });

const maxAssignmentLimitErrors = computed(() => {
  if (v$.value.maxAssignmentLimit.$error) {
    return t('INBOX_MGMT.AUTO_ASSIGNMENT.MAX_ASSIGNMENT_LIMIT_RANGE_ERROR');
  }
  return '';
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

const fetchAvailablePolicies = async () => {
  isLoadingPolicies.value = true;
  try {
    const response = await assignmentPoliciesAPI.get();
    availablePolicies.value = response.data;
  } catch (error) {
    availablePolicies.value = [];
  } finally {
    isLoadingPolicies.value = false;
  }
};

const linkPolicyToInbox = async policy => {
  isLinkingPolicy.value = true;
  try {
    await assignmentPoliciesAPI.setInboxPolicy(props.inbox.id, policy.id);
    assignmentPolicy.value = policy;
    showPolicyDropdown.value = false;
    useAlert(t('INBOX_MGMT.ASSIGNMENT.LINK_SUCCESS'));
  } catch (error) {
    useAlert(t('INBOX_MGMT.ASSIGNMENT.LINK_ERROR'));
  } finally {
    isLinkingPolicy.value = false;
  }
};

const navigateToAssignmentPolicies = () => {
  const accountId = route.params.accountId;
  router.push({
    name: 'agent_assignment_policy_index',
    params: { accountId },
  });
};

const policyMenuItems = computed(() => {
  const items = availablePolicies.value.map(policy => ({
    action: 'select_policy',
    value: policy.id,
    label: policy.name,
    icon: 'i-lucide-zap',
    policy,
  }));

  items.push({
    action: 'view_all',
    value: 'view_all',
    label: t('INBOX_MGMT.ASSIGNMENT.VIEW_ALL_POLICIES'),
    icon: 'i-lucide-arrow-right',
  });

  return items;
});

const handlePolicyMenuAction = ({ action, policy }) => {
  if (action === 'select_policy' && policy) {
    linkPolicyToInbox(policy);
  } else if (action === 'view_all') {
    navigateToAssignmentPolicies();
  }
  showPolicyDropdown.value = false;
};

const togglePolicyDropdown = () => {
  if (!showPolicyDropdown.value && availablePolicies.value.length === 0) {
    fetchAvailablePolicies();
  }
  showPolicyDropdown.value = !showPolicyDropdown.value;
};

const closePolicyDropdown = () => {
  showPolicyDropdown.value = false;
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

const updateInbox = async () => {
  try {
    const payload = {
      id: props.inbox.id,
      formData: false,
      enable_auto_assignment: enableAutoAssignment.value,
      auto_assignment_config: {
        max_assignment_limit: maxAssignmentLimit.value,
      },
    };
    await store.dispatch('inboxes/updateInbox', payload);
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
  }
};

const navigateToCreatePolicy = () => {
  const accountId = route.params.accountId;
  router.push({
    name: 'agent_assignment_policy_create',
    params: { accountId },
    query: { inboxId: props.inbox.id },
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
  maxAssignmentLimit.value =
    props.inbox.auto_assignment_config?.max_assignment_limit || null;
  fetchAttachedAgents();
  if (showAdvancedAssignmentUI.value) {
    fetchAssignmentPolicy();
    fetchAvailablePolicies();
  }
};

// Watch only inbox.id to avoid unnecessary refetches when other properties change
watch(() => props.inbox.id, setDefaults);

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
        <div class="flex items-start gap-3">
          <Switch
            v-model="enableAutoAssignment"
            class="flex-shrink-0 mt-0.5"
            @change="handleToggleAutoAssignment"
          />
          <div class="flex-grow">
            <label class="text-sm text-n-slate-12 font-medium mb-1">
              {{ $t('INBOX_MGMT.ASSIGNMENT.ENABLE_AUTO_ASSIGNMENT') }}
            </label>
            <p class="text-sm text-n-slate-11">
              {{ $t('INBOX_MGMT.ASSIGNMENT.DESCRIPTION') }}
            </p>
          </div>
        </div>

        <Transition
          enter-active-class="transition-all duration-200 ease-out"
          enter-from-class="opacity-0 -translate-y-2"
          enter-to-class="opacity-100 translate-y-0"
          leave-active-class="transition-all duration-150 ease-in"
          leave-from-class="opacity-100 translate-y-0"
          leave-to-class="opacity-0 -translate-y-2"
        >
          <div v-if="enableAutoAssignment" class="mt-6">
            <!-- Policy Card - When policy is attached -->
            <div
              v-if="showAdvancedAssignmentUI && assignmentPolicy"
              class="p-4 rounded-xl outline-1 outline-n-weak outline bg-n-solid-1 dark:bg-n-slate-1"
            >
              <div class="flex items-start gap-4">
                <div
                  class="flex-shrink-0 size-12 rounded-xl bg-n-slate-3 flex items-center justify-center"
                >
                  <span class="i-lucide-zap text-xl text-n-slate-11" />
                </div>
                <div class="flex-grow">
                  <div class="flex items-start justify-between gap-4 mb-4">
                    <div class="flex flex-col items-start">
                      <span class="text-base font-medium text-n-slate-12 mb-1">
                        {{ assignmentPolicy.name }}
                      </span>
                      <p class="text-sm text-n-slate-11">
                        {{ $t('INBOX_MGMT.ASSIGNMENT.POLICY_LABEL') }}
                      </p>
                    </div>
                    <NextButton
                      icon="i-lucide-trash-2"
                      ghost
                      ruby
                      sm
                      @click="confirmDeletePolicy"
                    />
                  </div>

                  <ul class="space-y-2 mb-6">
                    <li class="flex items-center gap-2">
                      <span
                        class="w-1.5 h-1.5 rounded-full bg-n-slate-11 flex-shrink-0"
                      />
                      <span class="text-sm text-n-slate-12">
                        {{ assignmentOrderLabel }}
                      </span>
                    </li>
                    <li class="flex items-center gap-2">
                      <span
                        class="w-1.5 h-1.5 rounded-full bg-n-slate-11 flex-shrink-0"
                      />
                      <span class="text-sm text-n-slate-12">
                        {{ assignmentMethodLabel }}
                      </span>
                    </li>
                  </ul>

                  <div class="w-full h-px my-4 bg-n-weak" />

                  <NextButton
                    :label="$t('INBOX_MGMT.ASSIGNMENT.CUSTOMIZE_POLICY')"
                    icon="i-lucide-arrow-right"
                    trailing-icon
                    link
                    class="mb-2"
                    @click="navigateToAssignmentPolicyEdit"
                  />
                </div>
              </div>
            </div>

            <!-- Default Policy - When no custom policy attached but feature enabled -->
            <div
              v-else-if="
                showAdvancedAssignmentUI &&
                !assignmentPolicy &&
                !isLoadingPolicy
              "
              class="rounded-xl outline-1 outline-n-weak outline"
            >
              <!-- Default Policy Header -->
              <div class="p-4">
                <div class="flex items-start gap-4">
                  <div
                    class="flex-shrink-0 w-12 h-12 rounded-xl bg-n-slate-3 dark:bg-n-slate-4 flex items-center justify-center"
                  >
                    <i class="i-lucide-zap text-xl text-n-slate-11" />
                  </div>
                  <div class="flex-grow">
                    <h4 class="text-base font-medium text-n-slate-12 mb-1">
                      {{ $t('INBOX_MGMT.ASSIGNMENT.DEFAULT_POLICY_LINKED') }}
                    </h4>
                    <p class="text-sm text-n-slate-11">
                      {{
                        $t('INBOX_MGMT.ASSIGNMENT.DEFAULT_POLICY_DESCRIPTION')
                      }}
                    </p>
                  </div>
                </div>

                <!-- Action Buttons -->
                <div class="mt-5 flex items-center gap-3">
                  <div
                    v-if="!isLoadingPolicies && availablePolicies.length > 0"
                    v-on-click-outside="closePolicyDropdown"
                    class="relative"
                  >
                    <button
                      type="button"
                      class="inline-flex items-center gap-1.5 px-4 py-2 text-sm font-medium text-white bg-n-brand hover:bg-n-brand/90 rounded-lg transition-colors"
                      @click="togglePolicyDropdown"
                    >
                      <i class="i-lucide-link text-sm" />
                      {{ $t('INBOX_MGMT.ASSIGNMENT.LINK_EXISTING_POLICY') }}
                      <i
                        class="i-lucide-chevron-down text-sm transition-transform"
                        :class="{ 'rotate-180': showPolicyDropdown }"
                      />
                    </button>

                    <DropdownMenu
                      v-if="showPolicyDropdown"
                      class="top-full left-0 mt-2 min-w-72"
                      :menu-items="policyMenuItems"
                      :is-searching="isLoadingPolicies"
                      @action="handlePolicyMenuAction"
                    />
                  </div>

                  <button
                    type="button"
                    class="inline-flex items-center gap-1.5 px-4 py-2 text-sm font-medium text-n-slate-12 bg-n-slate-3 dark:bg-n-slate-4 hover:bg-n-slate-4 dark:hover:bg-n-slate-5 rounded-lg transition-colors"
                    @click="navigateToCreatePolicy"
                  >
                    <i class="i-lucide-plus text-sm" />
                    {{ $t('INBOX_MGMT.ASSIGNMENT.CREATE_NEW_POLICY') }}
                  </button>
                </div>
              </div>

              <!-- Default Rules Info -->
              <div class="px-4 py-4 border-t border-n-weak bg-n-slate-2">
                <div class="flex items-start gap-3">
                  <i class="i-lucide-info text-base text-n-slate-10 mt-0.5" />
                  <div>
                    <p class="text-sm text-n-slate-11 mb-2">
                      {{ $t('INBOX_MGMT.ASSIGNMENT.CURRENT_BEHAVIOR') }}
                    </p>
                    <ul class="space-y-1">
                      <li class="flex items-center gap-2">
                        <span
                          class="w-1 h-1 rounded-full bg-n-slate-10 flex-shrink-0"
                        />
                        <span class="text-sm text-n-slate-11">
                          {{ $t('INBOX_MGMT.ASSIGNMENT.DEFAULT_RULE_1') }}
                        </span>
                      </li>
                      <li class="flex items-center gap-2">
                        <span
                          class="w-1 h-1 rounded-full bg-n-slate-10 flex-shrink-0"
                        />
                        <span class="text-sm text-n-slate-11">
                          {{ $t('INBOX_MGMT.ASSIGNMENT.DEFAULT_RULE_2') }}
                        </span>
                      </li>
                    </ul>
                  </div>
                </div>
              </div>
            </div>

            <!-- Default Rules Card - Feature not enabled (no advanced_assignment) -->
            <div
              v-else-if="!showAdvancedAssignmentUI"
              class="p-4 rounded-xl outline outline-1 outline-n-weak -outline-offset-1"
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

                  <div class="w-full h-px bg-n-weak my-4" />

                  <!-- Upgrade prompt when advanced_assignment is not enabled -->
                  <div v-if="!hasAdvancedAssignment">
                    <p class="text-sm text-n-slate-11 mb-1">
                      {{ $t('INBOX_MGMT.ASSIGNMENT.UPGRADE_PROMPT') }}
                    </p>
                    <NextButton
                      :label="$t('INBOX_MGMT.ASSIGNMENT.UPGRADE_TO_BUSINESS')"
                      icon="i-lucide-arrow-right"
                      trailing-icon
                      link
                      @click="navigateToBilling"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </Transition>
      </template>

      <!-- Old UI for non-assignment_v2 -->
      <template v-else>
        <label class="w-3/4 settings-item">
          <div class="flex items-center gap-2">
            <input
              id="enableAutoAssignment"
              v-model="enableAutoAssignment"
              type="checkbox"
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

        <div v-if="enableAutoAssignment && isEnterprise" class="py-3">
          <woot-input
            v-model="maxAssignmentLimit"
            type="number"
            :class="{ error: v$.maxAssignmentLimit.$error }"
            :error="maxAssignmentLimitErrors"
            :label="$t('INBOX_MGMT.AUTO_ASSIGNMENT.MAX_ASSIGNMENT_LIMIT')"
            @blur="v$.maxAssignmentLimit.$touch"
          />

          <p class="pb-1 text-sm not-italic text-n-slate-11">
            {{ $t('INBOX_MGMT.AUTO_ASSIGNMENT.MAX_ASSIGNMENT_LIMIT_SUB_TEXT') }}
          </p>

          <NextButton
            :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
            :disabled="v$.maxAssignmentLimit.$invalid"
            @click="updateInbox"
          />
        </div>
      </template>
    </SettingsSection>

    <woot-modal
      v-if="showDeleteConfirmModal"
      :show="showDeleteConfirmModal"
      :on-close="cancelDeletePolicy"
    >
      <div class="p-6">
        <h3 class="text-lg font-medium text-n-slate-12 mb-4">
          {{ $t('INBOX_MGMT.ASSIGNMENT_POLICY.DELETE_CONFIRM_TITLE') }}
        </h3>
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
