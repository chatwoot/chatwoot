<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { vOnClickOutside } from '@vueuse/components';
import { useVuelidate } from '@vuelidate/core';
import { minValue } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { useConfig } from 'dashboard/composables/useConfig';
import SettingsFieldSection from 'dashboard/components-next/Settings/SettingsFieldSection.vue';
import SettingsAccordion from 'dashboard/components-next/Settings/SettingsAccordion.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';
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

const selectedAgentIds = ref([]);
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

const selectedAgentNames = computed(() =>
  selectedAgentIds.value.map(
    id => agentList.value.find(a => a.id === id)?.name ?? ''
  )
);

const agentMenuItems = computed(() =>
  agentList.value
    .filter(({ id }) => !selectedAgentIds.value.includes(id))
    .map(({ id, name, thumbnail, avatar_url }) => ({
      label: name,
      value: id,
      action: 'select',
      thumbnail: { name, src: thumbnail || avatar_url || '' },
    }))
);

const handleAgentAdd = ({ value }) => {
  if (!selectedAgentIds.value.includes(value)) {
    selectedAgentIds.value.push(value);
  }
};

const handleAgentRemove = index => {
  selectedAgentIds.value.splice(index, 1);
};

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

const assignmentHeader = computed(() =>
  hasAssignmentV2.value
    ? t('INBOX_MGMT.ASSIGNMENT.ENABLE_AUTO_ASSIGNMENT')
    : t('INBOX_MGMT.SETTINGS_POPUP.AUTO_ASSIGNMENT')
);

const assignmentDescription = computed(() =>
  hasAssignmentV2.value
    ? t('INBOX_MGMT.ASSIGNMENT.DESCRIPTION')
    : t('INBOX_MGMT.SETTINGS_POPUP.AUTO_ASSIGNMENT_SUB_TEXT')
);

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
    selectedAgentIds.value = inboxMembers.map(m => m.id);
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

const handleToggleAutoAssignment = async val => {
  enableAutoAssignment.value = val;
  try {
    const payload = {
      id: props.inbox.id,
      formData: false,
      enable_auto_assignment: val,
    };
    await store.dispatch('inboxes/updateInbox', payload);
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
  }
};

const updateAgents = async () => {
  isAgentListUpdating.value = true;
  try {
    await store.dispatch('inboxMembers/create', {
      inboxId: props.inbox.id,
      agentList: selectedAgentIds.value,
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
    <SettingsFieldSection
      :label="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS')"
      :help-text="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS_SUB_TEXT')"
      class="[&>div]:!items-start"
    >
      <div
        class="rounded-xl outline outline-1 -outline-offset-1 outline-n-weak hover:outline-n-strong px-2 py-2"
      >
        <TagInput
          :model-value="selectedAgentNames"
          :placeholder="$t('INBOX_MGMT.ADD.AGENTS.PICK_AGENTS')"
          :menu-items="agentMenuItems"
          show-dropdown
          skip-label-dedup
          :auto-open-dropdown="false"
          @add="handleAgentAdd"
          @remove="handleAgentRemove"
        />
      </div>

      <template #extra>
        <div class="grid grid-cols-1 lg:grid-cols-8">
          <div class="col-span-1 lg:col-span-2" />
          <div class="col-span-1 lg:col-span-6 mt-4 justify-self-end">
            <NextButton
              :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
              :is-loading="isAgentListUpdating"
              @click="updateAgents"
            />
          </div>
        </div>
      </template>
    </SettingsFieldSection>
    <SettingsAccordion
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.AGENT_ASSIGNMENT')"
      class="mt-6"
    >
      <SettingsToggleSection
        v-model="enableAutoAssignment"
        compact
        :header="assignmentHeader"
        :description="assignmentDescription"
        @update:model-value="handleToggleAutoAssignment"
      >
        <template
          v-if="enableAutoAssignment && (isEnterprise || hasAssignmentV2)"
          #editor
        >
          <!-- assignment_v2 UI -->
          <template v-if="hasAssignmentV2">
            <!-- Policy Card - When policy is attached -->
            <div
              v-if="showAdvancedAssignmentUI && assignmentPolicy"
              class="ltr:pr-0 rtl:pl-0 ltr:pl-4 rtl:pr-4 py-4"
            >
              <div class="flex items-start gap-4">
                <div
                  class="flex-shrink-0 size-10 rounded-xl bg-n-slate-3 flex items-center justify-center"
                >
                  <span class="i-lucide-zap text-xl text-n-slate-11" />
                </div>
                <div class="flex-grow">
                  <div
                    class="flex items-start justify-between gap-4 mb-4 ltr:pr-4 rtl:pl-4"
                  >
                    <div class="flex flex-col items-start">
                      <span class="text-heading-3 text-n-slate-12 mb-1">
                        {{ assignmentPolicy.name }}
                      </span>
                      <p class="text-body-main text-n-slate-11">
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
                      <span class="text-body-main text-n-slate-12">
                        {{ assignmentOrderLabel }}
                      </span>
                    </li>
                    <li class="flex items-center gap-2">
                      <span
                        class="w-1.5 h-1.5 rounded-full bg-n-slate-11 flex-shrink-0"
                      />
                      <span class="text-body-main text-n-slate-12">
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
            >
              <!-- Default Policy Header -->
              <div class="p-4">
                <div class="flex items-start gap-4">
                  <div
                    class="flex-shrink-0 size-10 rounded-xl bg-n-slate-3 dark:bg-n-slate-4 flex items-center justify-center"
                  >
                    <i class="i-lucide-zap text-xl text-n-slate-11" />
                  </div>
                  <div class="flex-grow">
                    <h4 class="text-heading-3 text-n-slate-12 mb-0.5">
                      {{ $t('INBOX_MGMT.ASSIGNMENT.DEFAULT_POLICY_LINKED') }}
                    </h4>
                    <p class="text-body-main text-n-slate-11">
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
                    <NextButton
                      icon="i-lucide-link"
                      sm
                      @click="togglePolicyDropdown"
                    >
                      {{ $t('INBOX_MGMT.ASSIGNMENT.LINK_EXISTING_POLICY') }}
                      <Icon
                        icon="i-lucide-chevron-down"
                        class="transition-transform flex-shrink-0"
                        :class="{ 'rotate-180': showPolicyDropdown }"
                      />
                    </NextButton>

                    <DropdownMenu
                      v-if="showPolicyDropdown"
                      class="top-full ltr:left-0 rtl:right-0 mt-2 max-w-64 max-h-72 overflow-y-auto"
                      :menu-items="policyMenuItems"
                      :is-searching="isLoadingPolicies"
                      @action="handlePolicyMenuAction"
                    />
                  </div>

                  <NextButton
                    icon="i-lucide-plus"
                    :label="$t('INBOX_MGMT.ASSIGNMENT.CREATE_NEW_POLICY')"
                    slate
                    faded
                    sm
                    @click="navigateToCreatePolicy"
                  />
                </div>
              </div>

              <!-- Default Rules Info -->
              <div
                class="px-4 py-4 border-t border-n-weak bg-n-slate-2 rounded-b-xl"
              >
                <div class="flex items-start gap-3">
                  <Icon icon="i-lucide-info" class="mt-0.5 text-n-slate-11" />
                  <div>
                    <p class="text-body-main text-n-slate-11 mb-2">
                      {{ $t('INBOX_MGMT.ASSIGNMENT.CURRENT_BEHAVIOR') }}
                    </p>
                    <ul class="space-y-1">
                      <li class="flex items-center gap-2">
                        <span
                          class="w-1 h-1 rounded-full bg-n-slate-10 flex-shrink-0"
                        />
                        <span class="text-body-main text-n-slate-11">
                          {{ $t('INBOX_MGMT.ASSIGNMENT.DEFAULT_RULE_1') }}
                        </span>
                      </li>
                      <li class="flex items-center gap-2">
                        <span
                          class="w-1 h-1 rounded-full bg-n-slate-10 flex-shrink-0"
                        />
                        <span class="text-body-main text-n-slate-11">
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
              class="ltr:pr-0 rtl:pl-0 ltr:pl-4 rtl:pr-4 py-4"
            >
              <div class="flex items-start gap-4">
                <div
                  class="flex-shrink-0 size-10 rounded-xl bg-n-slate-3 dark:bg-n-slate-4 flex items-center justify-center"
                >
                  <Icon icon="i-lucide-zap" class="text-xl text-n-slate-11" />
                </div>
                <div class="flex-grow">
                  <h4 class="text-heading-3 text-n-slate-12 mb-0.5">
                    {{ $t('INBOX_MGMT.ASSIGNMENT.DEFAULT_RULES_TITLE') }}
                  </h4>
                  <p class="text-body-main text-n-slate-11 mb-4">
                    {{ $t('INBOX_MGMT.ASSIGNMENT.DEFAULT_RULES_DESCRIPTION') }}
                  </p>

                  <ul class="space-y-2 mb-6">
                    <li class="flex items-center gap-2">
                      <span
                        class="w-1.5 h-1.5 rounded-full bg-n-slate-11 flex-shrink-0"
                      />
                      <span class="text-body-main text-n-slate-12">
                        {{ $t('INBOX_MGMT.ASSIGNMENT.DEFAULT_RULE_1') }}
                      </span>
                    </li>
                    <li class="flex items-center gap-2">
                      <span
                        class="w-1.5 h-1.5 rounded-full bg-n-slate-11 flex-shrink-0"
                      />
                      <span class="text-body-main text-n-slate-12">
                        {{ $t('INBOX_MGMT.ASSIGNMENT.DEFAULT_RULE_2') }}
                      </span>
                    </li>
                  </ul>

                  <div class="w-full h-px bg-n-weak my-4" />

                  <!-- Upgrade prompt when advanced_assignment is not enabled -->
                  <div v-if="!hasAdvancedAssignment">
                    <p class="text-body-main text-n-slate-11 mb-1">
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
          </template>

          <!-- Old UI for non-assignment_v2 -->
          <template v-else-if="isEnterprise">
            <div class="p-4">
              <woot-input
                v-model="maxAssignmentLimit"
                type="number"
                :class="{ error: v$.maxAssignmentLimit.$error }"
                :error="maxAssignmentLimitErrors"
                :label="$t('INBOX_MGMT.AUTO_ASSIGNMENT.MAX_ASSIGNMENT_LIMIT')"
                class="[&>input]:!mb-0"
                @blur="v$.maxAssignmentLimit.$touch"
              />

              <p class="mt-1.5 text-label-small text-n-slate-11">
                {{
                  $t('INBOX_MGMT.AUTO_ASSIGNMENT.MAX_ASSIGNMENT_LIMIT_SUB_TEXT')
                }}
              </p>

              <div class="flex justify-end mt-4">
                <NextButton
                  :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
                  :disabled="v$.maxAssignmentLimit.$invalid"
                  @click="updateInbox"
                />
              </div>
            </div>
          </template>
        </template>
      </SettingsToggleSection>
    </SettingsAccordion>

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
