<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useConfig } from 'dashboard/composables/useConfig';
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';
import BasePaywallModal from '../../components/BasePaywallModal.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components/widgets/forms/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import MultiSelect from 'dashboard/components-next/filter/inputs/MultiSelect.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const route = useRoute();
const router = useRouter();
const store = useStore();
const getters = useStoreGetters();
const { t } = useI18n();
const { isEnterprise } = useConfig();

const isEditMode = computed(() => !!route.params.id);
const policyId = computed(() => route.params.id);

const uiFlags = computed(() => getters['agentCapacity/getUIFlags'].value);
const agents = computed(() => getters['agents/getAgents'].value);
const inboxes = computed(() => getters['inboxes/getInboxes'].value);

const loading = ref(false);
const showPaywallModal = ref(false);
const formData = ref({
  name: '',
  description: '',
  exclusion_rules: {
    labels: [],
    hours_threshold: 24,
  },
  inbox_limits: [], // Array of { inbox_id, conversation_limit }
  selected_agents: [], // For MultiSelect component
});

const errors = ref({});

const addInboxLimit = () => {
  formData.value.inbox_limits.push({
    inbox_id: '',
    conversation_limit: 10,
  });
};

const removeInboxLimit = index => {
  formData.value.inbox_limits.splice(index, 1);
};

const loadPolicy = async () => {
  try {
    loading.value = true;
    const policy = await store.dispatch('agentCapacity/show', policyId.value);
    formData.value = {
      name: policy.name,
      description: policy.description || '',
      exclusion_rules: policy.exclusion_rules || {
        labels: [],
        hours_threshold: 24,
      },
      inbox_limits: Array.isArray(policy.inbox_limits)
        ? policy.inbox_limits
        : [],
      selected_agents:
        policy.users?.map(user => ({ id: user.id, name: user.name })) || [],
    };
  } catch (error) {
    useAlert('Failed to load capacity policy');
    router.push({ name: 'assignment_capacity_list' });
  } finally {
    loading.value = false;
  }
};

const validateForm = () => {
  errors.value = {};

  if (!formData.value.name.trim()) {
    errors.value.name = 'Policy name is required';
  }

  if (!formData.value.selected_agents.length) {
    errors.value.selected_agents = 'At least one agent must be selected';
  }

  // Validate inbox limits
  for (let i = 0; i < formData.value.inbox_limits.length; i++) {
    const limit = formData.value.inbox_limits[i];
    if (!limit.inbox_id) {
      errors.value[`inbox_limit_${i}_inbox`] = 'Please select an inbox';
    }
    if (!limit.conversation_limit || limit.conversation_limit < 1) {
      errors.value[`inbox_limit_${i}_limit`] =
        'Conversation limit must be at least 1';
    }
  }

  return Object.keys(errors.value).length === 0;
};

const savePolicy = async () => {
  if (!validateForm()) return;

  try {
    const payload = {
      name: formData.value.name.trim(),
      description: formData.value.description.trim(),
      exclusion_rules: formData.value.exclusion_rules,
    };

    let policyToUse;
    if (isEditMode.value) {
      // Update policy
      policyToUse = await store.dispatch('agentCapacity/update', {
        id: policyId.value,
        ...payload,
      });
      useAlert('Capacity policy updated successfully');
    } else {
      // Create policy
      policyToUse = await store.dispatch('agentCapacity/create', payload);
      useAlert('Capacity policy created successfully');
    }

    const actualPolicyId = policyToUse?.id || policyId.value;

    // Handle inbox limits
    if (isEditMode.value) {
      // For editing, handle both additions and removals
      const updatedPolicy = await store.dispatch(
        'agentCapacity/show',
        actualPolicyId
      );
      const existingInboxIds =
        updatedPolicy.inbox_limits?.map(limit => limit.inbox_id) || [];
      const currentInboxIds = formData.value.inbox_limits
        .map(limit => limit.inbox_id)
        .filter(id => id);

      // Remove inbox limits that are no longer configured
      const inboxesToRemove = existingInboxIds.filter(
        inboxId => !currentInboxIds.includes(inboxId)
      );
      for (const inboxId of inboxesToRemove) {
        await store.dispatch('agentCapacity/removeInboxLimit', {
          id: actualPolicyId,
          inboxId: inboxId,
        });
      }
    }

    // Set/update inbox limits
    for (const limit of formData.value.inbox_limits) {
      if (limit.inbox_id && limit.conversation_limit) {
        await store.dispatch('agentCapacity/setInboxLimit', {
          id: actualPolicyId,
          inboxId: limit.inbox_id,
          conversationLimit: limit.conversation_limit,
        });
      }
    }

    // Handle agent assignments
    const currentAgentIds = formData.value.selected_agents.map(
      agent => agent.id
    );

    if (isEditMode.value) {
      // For editing, we need to handle both additions and removals
      // Get the current policy state to compare
      const updatedPolicy = await store.dispatch(
        'agentCapacity/show',
        actualPolicyId
      );
      const existingAgentIds = updatedPolicy.users?.map(user => user.id) || [];

      // Remove agents that are no longer selected
      const agentsToRemove = existingAgentIds.filter(
        agentId => !currentAgentIds.includes(agentId)
      );
      for (const agentId of agentsToRemove) {
        await store.dispatch('agentCapacity/removeUser', {
          id: actualPolicyId,
          userId: agentId,
        });
      }

      // Add newly selected agents
      const agentsToAdd = currentAgentIds.filter(
        agentId => !existingAgentIds.includes(agentId)
      );
      for (const agentId of agentsToAdd) {
        await store.dispatch('agentCapacity/assignUser', {
          id: actualPolicyId,
          userId: agentId,
        });
      }
    } else {
      // For new policies, just assign all selected agents
      for (const agentId of currentAgentIds) {
        await store.dispatch('agentCapacity/assignUser', {
          id: actualPolicyId,
          userId: agentId,
        });
      }
    }

    // Refresh the capacity policies list to show updated data
    await store.dispatch('agentCapacity/get');
    router.push({ name: 'assignment_capacity_list' });
  } catch (error) {
    const message = isEditMode.value
      ? 'Failed to update capacity policy'
      : 'Failed to create capacity policy';
    useAlert(message);
  }
};

const cancel = () => {
  router.push({ name: 'assignment_capacity_list' });
};

onMounted(async () => {
  await Promise.all([
    store.dispatch('agents/get'),
    store.dispatch('inboxes/get'),
  ]);

  if (isEditMode.value) {
    await loadPolicy();
  }
});
</script>

<template>
  <div>
    <BaseSettingsHeader
      :title="isEditMode ? 'Edit Capacity Policy' : 'Create Capacity Policy'"
      description="Configure conversation limits and agent assignments for this policy"
      back-button-label="Back to Capacity Management"
      @back="cancel"
    />

    <div v-if="loading" class="flex items-center justify-center h-64">
      <Spinner :size="48" />
    </div>

    <div v-else class="max-w-3xl p-8">
      <form @submit.prevent="savePolicy">
        <div class="space-y-6">
          <!-- Basic Information -->
          <div
            class="bg-white rounded-lg shadow-sm border border-slate-200 p-6"
          >
            <h3 class="text-lg font-medium mb-4">Basic Information</h3>
            <div class="space-y-4">
              <Input
                v-model="formData.name"
                label="Policy Name"
                placeholder="e.g., Standard Agent Capacity"
                :error="errors.name"
                required
              />

              <TextArea
                v-model="formData.description"
                label="Description"
                placeholder="Describe the purpose of this capacity policy"
                rows="3"
              />
            </div>
          </div>

          <!-- Inbox-Specific Limits -->
          <div
            class="bg-white rounded-lg shadow-sm border border-slate-200 p-6"
          >
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-medium">Inbox Capacity Limits</h3>
              <Button variant="ghost" icon="add" @click="addInboxLimit">
                Add Inbox Limit
              </Button>
            </div>

            <div
              v-if="!formData.inbox_limits.length"
              class="text-slate-500 text-sm text-center py-8"
            >
              No inbox limits configured. Click "Add Inbox Limit" to set
              capacity limits for specific inboxes.
            </div>

            <div v-else class="space-y-4">
              <div
                v-for="(limit, index) in formData.inbox_limits"
                :key="index"
                class="flex items-end gap-4 p-4 border border-slate-200 rounded-lg"
              >
                <div class="flex-1">
                  <label class="block text-sm font-medium mb-1">Inbox</label>
                  <select
                    v-model="limit.inbox_id"
                    class="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500"
                    :class="{
                      'border-red-500': errors[`inbox_limit_${index}_inbox`],
                    }"
                  >
                    <option value="">Select an inbox</option>
                    <option
                      v-for="inbox in inboxes"
                      :key="inbox.id"
                      :value="inbox.id"
                    >
                      {{ inbox.name }}
                    </option>
                  </select>
                  <div
                    v-if="errors[`inbox_limit_${index}_inbox`]"
                    class="text-red-500 text-xs mt-1"
                  >
                    {{ errors[`inbox_limit_${index}_inbox`] }}
                  </div>
                </div>

                <div class="w-32">
                  <Input
                    v-model.number="limit.conversation_limit"
                    type="number"
                    label="Limit"
                    placeholder="10"
                    :error="errors[`inbox_limit_${index}_limit`]"
                    min="1"
                    required
                  />
                </div>

                <Button
                  variant="ghost"
                  color="ruby"
                  icon="delete"
                  @click="removeInboxLimit(index)"
                />
              </div>
            </div>
          </div>

          <!-- Exclusion Rules -->
          <div
            class="bg-white rounded-lg shadow-sm border border-slate-200 p-6"
          >
            <h3 class="text-lg font-medium mb-4">Exclusion Rules</h3>
            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium mb-2">Exclude conversations with labels</label>
                <Input
                  v-model="formData.exclusion_rules.labels"
                  placeholder="vip, escalated (comma-separated)"
                  help-text="Conversations with these labels won't count towards capacity"
                />
              </div>

              <Input
                v-model.number="formData.exclusion_rules.hours_threshold"
                type="number"
                label="Exclude conversations older than (hours)"
                placeholder="24"
                help-text="Conversations created before this many hours ago won't count towards capacity"
                min="1"
              />
            </div>
          </div>

          <!-- Agent Assignment -->
          <div
            class="bg-white rounded-lg shadow-sm border border-slate-200 p-6"
          >
            <h3 class="text-lg font-medium mb-4">Agent Assignment</h3>
            <MultiSelect
              v-model="formData.selected_agents"
              :options="agents"
              label="Assigned Agents"
              placeholder="Select agents to apply this policy"
              :error="errors.selected_agents"
              track-by="id"
              label-key="name"
              required
            >
              <template #option="{ option }">
                <div class="flex items-center gap-2">
                  <img
                    :src="option.avatar_url"
                    :alt="option.name"
                    class="w-6 h-6 rounded-full"
                  />
                  <span>{{ option.name }}</span>
                </div>
              </template>
            </MultiSelect>

            <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mt-4">
              <p class="text-sm text-blue-800">
                <strong>Note:</strong>
                Agents will be limited by the conversation counts configured in
                this policy. Conversations matching exclusion rules won't count
                towards their capacity.
              </p>
            </div>
          </div>
        </div>

        <div class="flex justify-end gap-3 mt-8">
          <Button variant="ghost" @click="cancel"> Cancel </Button>
          <Button
            type="submit"
            variant="primary"
            :is-loading="uiFlags.isCreating || uiFlags.isUpdating"
          >
            {{ isEditMode ? 'Update Policy' : 'Create Policy' }}
          </Button>
        </div>
      </form>
    </div>

    <!-- Removed BasePaywallModal for Enterprise accounts -->
  </div>
</template>
