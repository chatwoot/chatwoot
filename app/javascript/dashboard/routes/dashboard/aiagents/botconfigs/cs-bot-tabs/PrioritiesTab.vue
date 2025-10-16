<script setup>
import { reactive, ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import aiAgents from '../../../../../api/aiAgents';

const props = defineProps({
  data: {
    type: Object,
    required: true,
  },
  agentType: {
    type: String,
    required: true,
    validator: (value) => ['customer_service', 'lead_generation'].includes(value)
  },
  defaultPriorities: {
    type: Array,
    default: () => []
  }
});

const { t } = useI18n();

const priorities = reactive([]);
const expandedPriorities = ref({});
const validation = reactive({
  priorities: {}
});
const isSaving = ref(false);

// Agent type configuration mapping
const agentConfig = {
  customer_service: {
    titleKey: 'AGENT_MGMT.CSBOT.TICKET.PRIORITY_TITLE',
    nameLabel: 'AGENT_MGMT.CSBOT.TICKET.PRIORITY_PLACEHOLDER',
    conditionLabel: 'AGENT_MGMT.CSBOT.TICKET.PRIORITY_CONDITION',
    conditionPlaceholder: 'AGENT_MGMT.CSBOT.TICKET.CONDITION_PLACEHOLDER',
    addButton: 'AGENT_MGMT.CSBOT.TICKET.ADD_PRIORITY',
    saveSuccess: 'AGENT_MGMT.CSBOT.TICKET.SAVE_SUCCESS',
    saveError: 'AGENT_MGMT.CSBOT.TICKET.SAVE_ERROR',
    validationError: 'AGENT_MGMT.CSBOT.TICKET.VALIDATION_ERROR',
    errorKey: 'AGENT_MGMT.CSBOT.TICKET.ERROR',
    dupeErrorKey: 'AGENT_MGMT.CSBOT.TICKET.DUPE_ERROR'
  },
  lead_generation: {
    titleKey: 'AGENT_MGMT.LEADGENBOT.PRIORITY.PRIORITY_TITLE',
    nameLabel: 'AGENT_MGMT.LEADGENBOT.PRIORITY.PRIORITY_PLACEHOLDER',
    conditionLabel: 'AGENT_MGMT.LEADGENBOT.PRIORITY.PRIORITY_CONDITION',
    conditionPlaceholder: 'AGENT_MGMT.LEADGENBOT.PRIORITY.CONDITION_PLACEHOLDER',
    addButton: 'AGENT_MGMT.LEADGENBOT.PRIORITY.ADD_PRIORITY',
    saveSuccess: 'AGENT_MGMT.LEADGENBOT.PRIORITY.SAVE_SUCCESS',
    saveError: 'AGENT_MGMT.LEADGENBOT.PRIORITY.SAVE_ERROR',
    validationError: 'AGENT_MGMT.CSBOT.TICKET.VALIDATION_ERROR',
    errorKey: 'AGENT_MGMT.CSBOT.TICKET.ERROR',
    dupeErrorKey: 'AGENT_MGMT.CSBOT.TICKET.DUPE_ERROR'
  }
};

const config = computed(() => agentConfig[props.agentType] || agentConfig.customer_service);

// Load priorities from backend when data arrives
watch(
  () => props.data,
  (newData) => {
    if (!newData?.display_flow_data) return

    const flowData = newData.display_flow_data
    const agentIndex = flowData.enabled_agents.indexOf(props.agentType);
    
    if (agentIndex === -1) return // Skip if agent not in flow

    const priorityConfig = flowData.agents_config?.[agentIndex]?.configurations?.priority
    if (Array.isArray(priorityConfig) && priorityConfig.length > 0) {
      priorities.splice(0, priorities.length, ...priorityConfig.map(c => ({
        name: c.key || '',
        condition: c.conditions || ''
      })));
    } else if (props.defaultPriorities.length > 0) {
      // Use default priorities if no config exists
      priorities.splice(0, priorities.length, ...props.defaultPriorities.map(p => ({
        name: p.name || p,
        condition: p.condition || ''
      })));
    }

    // Auto-expand all loaded priorities
    priorities.forEach((_, i) => {
      expandedPriorities.value[i] = true
    })
  },
  { immediate: true, deep: true }
);

function validatePriorityName(index) {
  const name = priorities[index]?.name?.trim();
  if (!name) {
    validation.priorities[index] = t(config.value.errorKey)
    return false
  }
  
  const duplicateIndex = priorities.findIndex((p, i) => 
    i !== index && p.name?.trim().toLowerCase() === name.toLowerCase()
  );
  if (duplicateIndex !== -1) {
    validation.priorities[index] = t(config.value.dupeErrorKey)
    return false
  }
  
  delete validation.priorities[index]
  return true
}

function addPriority() {
  const newIndex = priorities.length;
  priorities.push({ name: '', condition: '' })
  expandedPriorities.value[newIndex] = true;
}

function togglePriorityExpand(index) {
  expandedPriorities.value[index] = !expandedPriorities.value[index];
}

function removePriority(index) {
  priorities.splice(index, 1)
  delete validation.priorities[index]
  const newValidation = {}
  Object.keys(validation.priorities).forEach(key => {
    const keyIndex = parseInt(key)
    if (keyIndex > index) {
      newValidation[keyIndex - 1] = validation.priorities[keyIndex]
    } else if (keyIndex < index) {
      newValidation[keyIndex] = validation.priorities[keyIndex]
    }
  })
  validation.priorities = newValidation
}

async function save() {
  try {
    isSaving.value = true
    
    // Validate all priorities
    let isValid = true
    priorities.forEach((_, index) => {
      if (!validatePriorityName(index)) {
        isValid = false
      }
    });
    
    if (!isValid) {
      useAlert(t(config.value.validationError))
      return;
    }

    let flowData = props.data.display_flow_data;
    let priorityItems = [];
    priorities.forEach((item,  _) => {
      priorityItems.push({
        key: item.name,
        conditions: item.condition,
      });
    });
    
    const agentIndex = flowData.enabled_agents.indexOf(props.agentType);
    
    if (agentIndex === -1) {
      useAlert('Agent not found in flow');
      return;
    }
    
    // Initialize configurations if not exists
    if (!flowData.agents_config[agentIndex].configurations) {
      flowData.agents_config[agentIndex].configurations = {};
    }
    
    flowData.agents_config[agentIndex].configurations.priority = priorityItems;

    const payload = {
      flow_data: flowData,
    };
    
    await aiAgents.updateAgent(props.data.id, payload);
    useAlert(t(config.value.saveSuccess));
  } catch (e) {
    console.error(e);
    useAlert(t(config.value.saveError));
  } finally {
    isSaving.value = false;
  }
}
</script>

<template>
  <div class="flex flex-row gap-4">
    <div class="flex-1 min-w-0 flex flex-col justify-stretch gap-4">
      <div class="space-y-4">
        <div
          v-for="(priority, index) in priorities"
          :key="index"
          class="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl hover:shadow-md transition-all duration-200 hover:border-slate-300 dark:hover:border-slate-600"
        >
          <div 
            class="flex items-center justify-between p-4 cursor-pointer"
            @click="() => togglePriorityExpand(index)"
          >
            <div class="flex items-center gap-3">
              <div class="w-2 h-2 bg-green-500 rounded-full"></div>
              <h3 class="text-sm font-medium text-slate-700 dark:text-slate-300">
                {{ $t(config.titleKey) }} #{{ index + 1 }}
              </h3>
              <span v-if="priority.name" class="text-xs text-slate-500 dark:text-slate-400 truncate max-w-xs">
                - {{ priority.name }}
              </span>
            </div>
            <div class="flex items-center gap-2">
              <Button
                variant="ghost"
                color="ruby"
                icon="i-lucide-trash"
                size="sm"
                :disabled="false"
                @click.stop="() => removePriority(index)"
                class="opacity-70 hover:opacity-100"
              />
              <svg 
                class="w-4 h-4 text-slate-400 transition-transform duration-200"
                :class="{ 'rotate-180': expandedPriorities[index] }"
                fill="none" 
                stroke="currentColor" 
                viewBox="0 0 24 24"
              >
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
              </svg>
            </div>
          </div>
          
          <div 
            v-show="expandedPriorities[index]"
            class="px-4 pb-4 border-t border-slate-200 dark:border-slate-700"
          >
            <div class="pt-4 grid grid-cols-1 lg:grid-cols-2 gap-6">
              <div class="space-y-2">
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300">
                  {{ $t(config.nameLabel) }}
                  <span class="text-red-500">*</span>
                </label>
                <textarea
                  v-model="priority.name"
                  @blur="validatePriorityName(index)"
                  @input="validatePriorityName(index)"
                  :placeholder="$t(config.nameLabel)"
                  :class="[
                    'w-full px-3 py-2.5 text-sm rounded-lg border transition-all duration-200 resize-none',
                    'bg-slate-50 dark:bg-slate-900/50',
                    'focus:ring-2 focus:ring-green-500/20 focus:border-green-500',
                    'hover:border-slate-300 dark:hover:border-slate-600',
                    validation.priorities[index] 
                      ? 'border-red-300 focus:border-red-500 focus:ring-red-500/20' 
                      : 'border-slate-200 dark:border-slate-700',
                    'placeholder:text-slate-400 dark:placeholder:text-slate-500'
                  ]"
                  rows="3"
                ></textarea>
                <p v-if="validation.priorities[index]" class="text-red-500 text-xs">
                  {{ validation.priorities[index] }}
                </p>
              </div>
              
              <div class="space-y-2">
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300">
                  {{ $t(config.conditionLabel) }}
                </label>
                <textarea
                  v-model="priority.condition"
                  :placeholder="$t(config.conditionPlaceholder)"
                  class="w-full px-3 py-2.5 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900/50 hover:border-slate-300 dark:hover:border-slate-600 focus:ring-2 focus:ring-green-500/20 focus:border-green-500 transition-all duration-200 resize-none placeholder:text-slate-400 dark:placeholder:text-slate-500"
                  rows="3"
                ></textarea>
              </div>
            </div>
          </div>
        </div>
      </div>

      <Button 
        id="btnAddPriority" 
        class="w-full py-3 border-2 border-dashed border-slate-300 dark:border-slate-600 text-slate-500 dark:text-slate-400 hover:border-green-400 hover:text-green-600 transition-all duration-200 rounded-xl bg-transparent hover:bg-green-50 dark:hover:bg-green-900/10" 
        variant="ghost"
        @click="addPriority"
      >
        <span class="flex items-center gap-2">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
          </svg>
          {{ $t(config.addButton) }}
        </span>
      </Button>
    </div>
    
    <div class="w-[240px] flex flex-col gap-3">
      <div class="sticky top-4 bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-4 shadow-sm">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
            <svg class="w-5 h-5 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z"></path>
            </svg>
          </div>
          <div>
            <!-- <h3 class="font-semibold text-slate-700 dark:text-slate-300">{{ $t(config.titleKey) }}</h3> -->
            <p class="text-sm text-slate-500 dark:text-slate-400">{{ priorities.length }} items</p>
          </div>
        </div>
        
        <Button
          class="w-full"
          :is-loading="isSaving"
          :disabled="isSaving"
          @click="() => save()"
        >
          <span class="flex items-center gap-2">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
            </svg>
            {{ $t('AGENT_MGMT.CSBOT.TICKET.SAVE_BUTTON') }}
          </span>
        </Button>
        
      </div>
    </div>
  </div>
</template>