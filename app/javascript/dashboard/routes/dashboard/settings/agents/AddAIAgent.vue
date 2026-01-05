<script setup>
import { ref, onMounted, computed } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useVuelidate } from '@vuelidate/core';
import { required, requiredIf, helpers } from '@vuelidate/validators';
import Button from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['close']);
const store = useStore();
const { t } = useI18n();

const uiFlags = computed(() => store.getters['agents/getUIFlags']);

// Form data
const selectedAIAgent = ref(null);
const selectedHumanAgent = ref(null);

// Data lists
const aiAgents = ref([]);
const humanAgents = ref([]);
const isLoadingAIAgents = ref(false);

const hasAgentKey = value => {
  if (!value) {
    return true;
  }
  return !!value.agent_key;
};

const rules = {
  selectedAIAgent: {
    required: helpers.withMessage(
      t('AGENT_MGMT.BLEEP_AGENT.FORM.AI_AGENT.ERROR'),
      required
    ),
    hasAgentKey: helpers.withMessage(
      t('AGENT_MGMT.BLEEP_AGENT.FORM.AI_AGENT.NO_REGIONS_ERROR'),
      hasAgentKey
    ),
  },
  selectedHumanAgent: {
    required: helpers.withMessage(
      t('AGENT_MGMT.BLEEP_AGENT.FORM.HUMAN_AGENT.ERROR'),
      requiredIf(() => {
        return humanAgents.value && humanAgents.value.length > 0;
      })
    ),
  },
};

const v$ = useVuelidate(rules, {
  selectedAIAgent,
  selectedHumanAgent,
});

// Fetch deployed AI agents from backend
const fetchAloostudioAgents = async () => {
  isLoadingAIAgents.value = true;
  try {
    const deployments = await store.dispatch(
      'agents/fetchAloostudioDeployments'
    );

    aiAgents.value = deployments.map(d => {
      // Extract region and channel info
      const regionName = d.region?.name || 'Unknown Region';
      const regionFlag = d.region?.flag || '';
      const channel = d.channel || 'unknown';

      // console.log('Deployment Index:', index);

      // Format channel name for display
      const channelDisplay = channel.charAt(0).toUpperCase() + channel.slice(1);

      // Create display name with region and channel
      const agentTitle = d.agent?.title || 'AI Agent';
      const displayName = `${agentTitle} (${regionFlag} ${regionName} - ${channelDisplay})`;

      const mappedAgent = {
        id: d.agent_id || d.id,
        name: displayName,
        original_name: agentTitle,
        region_id: d.region_id || '',
        region_name: regionName,
        region_flag: regionFlag,
        channel: channel,
        channel_display: channelDisplay,
        agent_key: d.agent_key || '',
        description: d.agent?.welcome_message || '',
        capabilities: d.agent?.category_names || [],
        language: d.languages || [],
        response_time: d.agent?.response_time || '',
        raw: d,
      };

      return mappedAgent;
    });
  } catch (error) {
    useAlert(t('AGENT_MGMT.ADD.API.BLEEP_FETCH_ERROR'));
  } finally {
    isLoadingAIAgents.value = false;
  }
};

const fetchHumanAgents = async () => {
  try {
    const response = await store.dispatch('agents/get');
    humanAgents.value = response.filter(agent => {
      // Exclude if it's an AI agent OR if the email starts with 'ai-agent-'
      return !agent.email.startsWith('ai-agent-');
    });
  } catch (error) {
    useAlert(t('AGENT_MGMT.ADD.API.HUMAN_AGENTS_FETCH_ERROR'));
  }
};

const addBleepAgent = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  try {
    // Construct unique email without repeated values
    const agentId = selectedAIAgent.value.id;
    const regionId = selectedAIAgent.value.region_id;
    const emailParts = ['ai-agent', agentId];
    if (regionId && regionId !== agentId) {
      emailParts.push(regionId.substring(0, 5));
    }
    const uniqueEmail = emailParts.join('-') + '@mg.aloochat.ai';

    const payload = {
      name: selectedAIAgent.value.name,
      is_ai: true,
      email: uniqueEmail,
      ai_agent_id: agentId,
      agent_key: selectedAIAgent.value.agent_key,
      human_agent_id: selectedHumanAgent.value,
    };

    await store.dispatch('agents/createBleepAgent', payload);
    useAlert(t('AGENT_MGMT.ADD.API.BLEEP_SUCCESS_MESSAGE'));
    emit('close');
  } catch (error) {
    const errorMessage =
      error.response?.data?.message ||
      t('AGENT_MGMT.ADD.API.BLEEP_ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

onMounted(() => {
  fetchAloostudioAgents();
  fetchHumanAgents();
});
</script>

<template>
  <form
    class="flex flex-col items-start w-full"
    @submit.prevent="addBleepAgent"
  >
    <!-- AI Agent Selection -->
    <div class="w-full">
      <label :class="{ error: v$.selectedAIAgent.$error }">
        {{ $t('AGENT_MGMT.BLEEP_AGENT.FORM.AI_AGENT.LABEL') }}
        <select v-model="selectedAIAgent" @change="v$.selectedAIAgent.$touch">
          <option value="">
            {{ $t('AGENT_MGMT.BLEEP_AGENT.FORM.AI_AGENT.PLACEHOLDER') }}
          </option>
          <option v-for="agent in aiAgents" :key="agent.id" :value="agent">
            {{ agent.name }}
          </option>
        </select>
        <span
          v-for="error of v$.selectedAIAgent.$errors"
          :key="error.$uid"
          class="message"
        >
          {{ error.$message }}
        </span>
      </label>
    </div>

    <!-- Human Agent Selection -->
    <div class="w-full">
      <label
        :class="{ error: v$.selectedHumanAgent.$error }"
        class="block text-sm font-medium text-slate-700 dark:text-slate-200"
      >
        {{ $t('AGENT_MGMT.BLEEP_AGENT.FORM.HUMAN_AGENT.LABEL') }}
      </label>
      <select
        v-if="humanAgents.length"
        v-model="selectedHumanAgent"
        @change="v$.selectedHumanAgent.$touch"
      >
        <option value="" disabled>
          {{ $t('AGENT_MGMT.BLEEP_AGENT.FORM.HUMAN_AGENT.PLACEHOLDER') }}
        </option>
        <option v-for="agent in humanAgents" :key="agent.id" :value="agent.id">
          {{ agent.name }}
        </option>
      </select>
      <p v-else class="text-sm text-slate-600 dark:text-slate-300">
        {{ $t('AGENT_MGMT.BLEEP_AGENT.FORM.HUMAN_AGENT.NO_AGENTS') }}
      </p>
      <span
        v-for="error of v$.selectedHumanAgent.$errors"
        :key="error.$uid"
        class="message"
      >
        {{ error.$message }}
      </span>
      <span class="help-text">
        {{ $t('AGENT_MGMT.BLEEP_AGENT.FORM.HUMAN_AGENT.HELP_TEXT') }}
      </span>
    </div>

    <!-- Action Buttons -->
    <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
      <Button
        faded
        slate
        type="reset"
        :label="$t('AGENT_MGMT.ADD.CANCEL_BUTTON_TEXT')"
        @click.prevent="emit('close')"
      />
      <Button
        type="submit"
        :label="$t('AGENT_MGMT.ADD.FORM.SUBMIT')"
        :disabled="
          v$.$invalid || humanAgents.length === 0 || uiFlags.isCreating
        "
        :is-loading="uiFlags.isCreating"
      />
    </div>
  </form>
</template>

<style scoped>
.w-full {
  margin-bottom: 1rem;
}

label {
  display: block;
  margin-bottom: 0.5rem;
}

select {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #e2e8f0;
  border-radius: 0.375rem;
}

.error select {
  border-color: #ef4444;
}

.message {
  color: #ef4444;
  font-size: 0.875rem;
  margin-top: 0.25rem;
  display: block;
}

.help-text {
  color: #6b7280;
  font-size: 0.875rem;
  margin-top: 0.25rem;
  display: block;
}
</style>
