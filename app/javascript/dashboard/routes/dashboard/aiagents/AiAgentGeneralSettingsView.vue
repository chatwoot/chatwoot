<script setup>
import {
  computed,
  nextTick,
  reactive,
  ref,
  useTemplateRef,
  watch,
  watchEffect,
} from 'vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import { required } from '@vuelidate/validators';
import useVuelidate from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import aiAgents from '../../../api/aiAgents';
import MarkdownIt from 'markdown-it';

const md = new MarkdownIt();

const props = defineProps({
  data: {
    type: Object,
    required: true,
  },
  botType: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();

// custom agent type
const isCustomAgent = computed(() => props.botType === 'custom_agent');

const chatflowId = ref();
const chatInput = ref('');
const messages = ref([]);
const sessionId = ref(crypto.randomUUID());
const loadingChat = ref(false);
const chatContainer = ref(null);
const knowledgeSources = ref([]);

// Fetch knowledge sources on mount or when agent data changes
watch(
  () => props.data,
  async v => {
    chatflowId.value = v?.chat_flow_id;
    if (v?.id) {
      try {
        const res = await aiAgents.getKnowledgeSources(v.id);
        knowledgeSources.value = res.data?.knowledge_source_texts || [];
      } catch (err) {
        console.error('Failed to fetch knowledge sources:', err);
        knowledgeSources.value = [];
      }
    }
  },
  { immediate: true }
);

watch(
  () => props.data,
  v => {
    chatflowId.value = v?.chat_flow_id;
  },
  {
    immediate: true,
  }
);

const state = reactive({
  name: '',
  description: '',
  business_info: '',
  welcoming_message: '',
  routing_conditions: '',
  has_website: '', // 'yes' or 'no'
  website_url: '',
});
const rules = {
  name: { required },
  description: {},
  business_info: { required },
  welcoming_message: {},
  routing_conditions: {},
  has_website: {},
  website_url: {},
};

const v$ = useVuelidate(rules, state);

// Inside the watch on props.data, after fetching knowledgeSources
// 🔁 Replace both watches with this single one:

watch(
  () => props.data,
  async v => {
    if (!v) return;

    // Sync chatflowId immediately
    chatflowId.value = v?.chat_flow_id;
    console.log("v:")
    console.log(v)
    // Start populating state from props.data
    state.name = v.name || '';
    // state.description = v.description || '';
    state.welcoming_message = v.display_flow_data.agents_config[0].bot_prompt.persona;
    state.routing_conditions = v.display_flow_data.agents_config[0].bot_prompt.handover_conditions;
    
    // 🚫 Do NOT set state.business_info from v.business_info!
    // Why? Because the real source of truth is knowledge_sources (tab:1)
    // If we set it here, it might get overwritten later — or worse, overwrite the real data.
    
    if (v.id) {
      try {
        const res = await aiAgents.getKnowledgeSources(v.id);
        knowledgeSources.value = res.data?.knowledge_source_texts || [];
        console.log("knowledgeSources value:")
        console.log(knowledgeSources.value)
        console.log("props.data:")
        console.log(props.data)
        console.log(props.data.display_flow_data)
        const flowData = props.data.display_flow_data;
        console.log("flowData:")
        console.log(flowData)
        const agents_config = flowData.agents_config;
        console.log(agents_config)
        // ✅ STEP 2: Update bot_prompt for every agent that is customer_service
        agents_config.forEach(agent_config => {
          if (agent_config.bot_prompt) {
            console.log(agents_config)
            state.welcoming_message = agent_config.bot_prompt.persona;
            state.routing_conditions = agent_config.bot_prompt.handover_conditions;
          }
        });
        // Now look for tab:1 content
        const knowledgeTab1 = knowledgeSources.value.find(k => k.tab === 1);
        if (knowledgeTab1) {
          state.business_info = knowledgeTab1.text;
        } else {
          // If no knowledge source for tab:1 exists, leave as empty (or set default)
          state.business_info = '';
        }
      } catch (err) {
        console.error('Failed to fetch knowledge sources:', err);
        state.business_info = ''; // fallback on error
      }
    }
  },
  { immediate: true }
);

const loadingSave = ref(false);

async function submit() {
  if (loadingSave.value) return;

  const isValid = await v$.value.$validate();
  if (!isValid) return;

  try {
    loadingSave.value = true;

    const agentId = props.data.id;
    const request = { ...state };
    console.log("state:")
    console.log(state)

    // 🔎 Find existing knowledge source for tab: 1
    const existingKnowledge = knowledgeSources.value.find(k => k.tab === 1);

    let knowledgeId = existingKnowledge?.id;

    // 🟡 If no knowledge source for tab:1 exists → create one
    if (!knowledgeId) {
      const createRes = await aiAgents.addKnowledgeText(agentId, {
        id: null,
        tab: 1,
        text: state.business_info || '<br>',
      });
      knowledgeId = createRes.data?.id;

      // 🛠 Also update local list so future edits work
      if (knowledgeId) {
        knowledgeSources.value.push({
          id: knowledgeId,
          tab: 1,
          text: state.business_info || '<br>',
        });
      }
    }

    // ✅ Now safely update with real `id`
    await aiAgents.updateKnowledgeText(agentId, {
      id: knowledgeId,
      tab: 1,
      text: state.business_info,
    });

    // ✅ Update agent info
    // ✅ STEP 1: Deep clone flowData to avoid mutating props
    const flowData = JSON.parse(JSON.stringify(props.data.display_flow_data));

    // ✅ STEP 2: Update bot_prompt for every agent that is customer_service
    flowData.agents_config.forEach(agent_config => {
      if (agent_config.bot_prompt) {
        agent_config.bot_prompt.persona = state.welcoming_message || agent_config.bot_prompt.persona;
        agent_config.bot_prompt.handover_conditions = state.routing_conditions || '';
        // Optionally reset to default if empty:
        // if (!state.routing_conditions) agent_config.bot_prompt.handover_conditions = '...default...'
      }
    });
    console.log(flowData);
    console.log(props.config);
    const payload = {
      flow_data: flowData,
    };
    // ✅ Properly await the API call
    await aiAgents.updateAgent(props.data.id, payload);

    // 🔄 Refresh agent data to get latest chat_flow_id
    const detailAgent = await aiAgents.detailAgent(agentId).then(v => v?.data);
    chatflowId.value = undefined;
    nextTick(() => {
      chatflowId.value = detailAgent?.chat_flow_id;
    });

    useAlert('Berhasil disimpan');
  } catch (error) {
    console.error('Error updating agent:', error);
    if (error.response) {
      console.error('Response data:', error.response.data);
      console.error('Status code:', error.response.status);
    } else if (error.request) {
      console.error('No response received:', error.request);
    } else {
      console.error('Error:', error.message);
    }
    useAlert('Gagal menyimpan data. Cek konsol untuk detail.', 'alert-danger');
  } finally {
    loadingSave.value = false;
  }
}

function scrollToBottom() {
  nextTick(() => {
    if (chatContainer.value) {
      chatContainer.value.scrollTop = chatContainer.value.scrollHeight;
    }
  });
}


function renderMarkdown(text) {
  return md.render(text);
}

async function chat() {
  if (loadingChat.value || !chatInput.value.trim()) return;

  const question = chatInput.value.trim();
  messages.value.push({
    role: 'user',
    content: question,
  });
  chatInput.value = '';
  scrollToBottom();

  try {
    loadingChat.value = true;
    const res = await aiAgents.chat(props.data.id, {
      question,
      session_id: sessionId.value,
    });
    
    messages.value.push({
      role: 'assistant',
      content: res.data.response,
    });
    scrollToBottom();
  } catch (error) {
    messages.value.push({
      role: 'assistant',
      content: 'Maaf, terjadi kesalahan saat memproses pertanyaan Anda.',
    });
    scrollToBottom();
  } finally {
    loadingChat.value = false;
  }
}

function resetChat() {
  messages.value = [];
  sessionId.value = crypto.randomUUID();
}
</script>

<template>
  <div class="flex flex-col lg:flex-row justify-stretch gap-4">
    <form class="lg:flex-1 lg:min-w-0" @submit.prevent="() => submit()">
      <div class="flex flex-col space-y-3">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <div>
            <label for="name">{{ t('AGENT_MGMT.FORM_CREATE.AI_AGENT_NAME') }}</label>
            <Input id="name" v-model="state.name" :placeholder="t('AGENT_MGMT.FORM_CREATE.AI_AGENT_NAME')" />
          </div>
          <!-- <div>
            <label for="description">{{ t('AGENT_MGMT.FORM_CREATE.AI_AGENT_DESC') }}</label>
            <Input
              id="description"
              v-model="state.description"
              :placeholder="t('AGENT_MGMT.FORM_CREATE.AI_AGENT_DESC')"
            />
          </div> -->
        </div>
        
        <!-- Only show these fields if NOT a custom agent -->
        <template v-if="!isCustomAgent">
          <div>
            <label for="welcome_message">{{ t('AGENT_MGMT.FORM_CREATE.AI_AGENT_PERSONA_LANG_STYLE') }}</label>
            <TextArea
              :placeholder="t('AGENT_MGMT.FORM_CREATE.AI_AGENT_PERSONA_LANG_STYLE_PLACEHOLDER')"            id="welcome_message"
              v-model="state.welcoming_message"
              custom-text-area-wrapper-class=""
              custom-text-area-class="!outline-none"
              auto-height
            />
          </div>
          <div>
            <label for="routing_conditions">{{ t('AGENT_MGMT.FORM_CREATE.ROUTING_CONDITION') }}</label>
            <TextArea
              id="routing_conditions"
              v-model="state.routing_conditions"
              custom-text-area-wrapper-class=""
              custom-text-area-class="!outline-none"
              :placeholder="t('AGENT_MGMT.FORM_CREATE.ROUTING_CONDITION_PLACEHOLDER')"
              auto-height
            />
          </div>
          <div>
            <label for="business_info">{{ t('AGENT_MGMT.FORM_CREATE.AI_AGENT_BUSINESS_INFO') }}</label>
            <TextArea
              id="business_info"
              v-model="state.business_info"
              custom-text-area-wrapper-class=""
              custom-text-area-class="!outline-none"
              auto-height
              :placeholder="t('AGENT_MGMT.FORM_CREATE.AI_AGENT_BUSINESS_INFO_PLACEHOLDER')"
            />
          </div>
        </template>
        
        <button v-if="!isCustomAgent" class="button self-start" type="submit" :disabled="loadingSave">
          <span v-if="loadingSave" class="mt-4 mb-4 spinner" />
          <span v-else>{{ t('AGENT_MGMT.FORM_CREATE.SUBMIT') }}</span>
        </button>
      </div>
    </form>
    <!-- Chat Preview Section -->
    <div class="h-[600px] w-full lg:h-[500px] lg:w-[350px]">
      <div class="w-full rounded-xl dark:bg-black-900/80 shadow-lg dark:shadow-slate-700 overflow-hidden flex flex-col h-full">
        <div class="bg-green-600 px-4 py-2 flex justify-end items-center">
          <button @click="resetChat" class="text-white hover:text-gray-200 flex items-center space-x-1">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
          </button>
        </div>
        <div ref="chatContainer" class="flex-1 flex flex-col space-y-4 p-4 overflow-y-auto">
          <div class="flex justify-start">
            <div class="bg-slate-50 dark:bg-slate-800 px-4 py-3 rounded-lg text-sm max-w-[90%]">
              <span class="text-[#000000] dark:text-white">Hai! Ada yang bisa saya bantu?</span>
            </div>
          </div>
          <div
            v-for="(message, index) in messages"
            :key="index"
            :class="message.role === 'user' ? 'flex justify-end' : 'flex justify-start'"
          >
            <div
              :class="[
                'px-4 py-2 rounded-lg text-sm max-w-[90%]',
                message.role === 'user' ? 'bg-green-600 text-white' : 'bg-slate-50 dark:bg-slate-800 text-[#000000] dark:text-white',
              ]"
              v-html="message.role === 'user' ? message.content.replace(/\n/g, '<br>') : renderMarkdown(message.content)"
            ></div>
          </div>
        </div>
        <form class="flex items-center p-4" @submit.prevent="chat">
          <Input v-model="chatInput" class="w-full" type="text" placeholder="Type your question" />
          <button 
            class="ml-3 bg-green-600 text-white p-2 rounded-lg hover:bg-green-700 relative"
            type="submit"
            :disabled="loadingChat"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12l15-6-6 15-2.25-6-6.75-3z" />
            </svg>
          </button>
        </form>
      </div>
    </div>
    <!-- Chat Preview Section -->
  </div>
</template>
