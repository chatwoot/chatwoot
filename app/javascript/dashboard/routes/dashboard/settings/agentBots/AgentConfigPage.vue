<script setup>
import { ref, computed, reactive, watch, onMounted } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';

import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import SettingIntroBanner from 'dashboard/components/widgets/SettingIntroBanner.vue';
import TabGeneral from './tabs/TabGeneral.vue';
import TabAssistant from './tabs/TabAssistant.vue';
import TabModel from './tabs/TabModel.vue';
import TabCapabilities from './tabs/TabCapabilities.vue';
import TabTools from './tabs/TabTools.vue';
import TabContent from './tabs/TabContent.vue';

const store = useStore();
const { t } = useI18n();
const route = useRoute();

const uiFlags = useMapGetter('agentBots/getUIFlags');
const getBot = useMapGetter('agentBots/getBot');

const botId = computed(() => Number(route.params.botId));
const bot = computed(() => getBot.value(botId.value));

const selectedTabIndex = ref(0);

const tabs = computed(() => [
  { key: 'general', name: t('AGENT_BOTS.CONFIG.TABS.GENERAL') },
  { key: 'assistant', name: t('AGENT_BOTS.CONFIG.TABS.ASSISTANT') },
  { key: 'model', name: t('AGENT_BOTS.CONFIG.TABS.MODEL') },
  { key: 'capabilities', name: t('AGENT_BOTS.CONFIG.TABS.CAPABILITIES') },
  { key: 'tools', name: t('AGENT_BOTS.CONFIG.TABS.TOOLS') },
  { key: 'content', name: t('AGENT_BOTS.CONFIG.TABS.CONTENT') },
]);

const defaultBehaviorConfig = () => ({
  industry_sector_type: 'automotive',
  response: {
    model_name: 'gpt-4o-mini',
    temperature: 0.4,
    response_word_limit: '50-70',
    max_context_tokens: 800,
  },
  modules: {
    general_response: { enabled: true },
    transfer_chat: { enabled: true },
    appointments: {
      enabled: false,
      actions: { create: true, reschedule: true, cancel: true },
      fallback: { strategy: 'transfer_advisor', phone_number: null, custom_message: null },
    },
    send_documents: { enabled: true, allowed_types: ['pdf', 'image'] },
    out_of_scope: { enabled: true, max_attempts: 3 },
  },
  tools: {
    search_product_info: { enabled: true, score_threshold: 0.75, top_k: 10, examples: [], custom_instructions: '' },
    get_all_products: { enabled: true, listing_mode: 'all', max_results: 0, show_prices_by_default: false, examples: [], custom_instructions: '' },
    get_faqs: { enabled: true, per_page: 8, examples: [], custom_instructions: '' },
    get_marketing_campaigns: { enabled: true, examples: [], custom_instructions: '' },
    get_kb_resources: { enabled: false, examples: [], custom_instructions: '' },
    send_document: { enabled: true, sources: ['catalog'], allowed_types: ['pdf', 'image'], examples: [], custom_instructions: '' },
    transfer_chat: { enabled: true, examples: [], custom_instructions: '' },
  },
  lead_warming: { enabled: true, auto_suggest_after_turns: 5, closing_phrases: [] },
  proactive_reengagement: {
    enabled: false,
    attempts: [
      { delay_value: 5,  delay_unit: 'minutes' },
      { delay_value: 15, delay_unit: 'minutes' },
      { delay_value: 45, delay_unit: 'minutes' },
    ],
    stop_conditions: {
      on_any_reply: true,
      on_resolved: true,
      on_agent_assigned: false,
    },
    stop_keywords: { case_insensitive: true, phrases: [] },
    reactivation: { on_bot_reply: true, exclude_if_cancelled_by: ['keyword', 'api_cancel'] },
  },
  module_fallbacks: {
    appointments: { strategy: 'transfer_advisor', phone_number: null, custom_message: null },
  },
  qualification_questions: [],
  additional_instructions: '',
});

const defaultAssistantConfig = () => ({
  preset: '',
  name: '',
  title: '',
  personality: '',
  tone: '',
  goal: '',
  speaking_style: '',
  inspiration: '',
});

const formState = reactive({
  name: '',
  description: '',
  outgoing_url: '',
  thumbnail: '',
  assistant_config: defaultAssistantConfig(),
  agent_behavior_config: defaultBehaviorConfig(),
  openai_api_key: '',
  google_api_key: '',
  has_openai_api_key: false,
  has_google_api_key: false,
});

const initForm = () => {
  const b = bot.value;
  if (!b || !b.id) return;

  formState.name = b.name || '';
  formState.description = b.description || '';
  formState.outgoing_url = b.outgoing_url || b.bot_config?.webhook_url || '';
  formState.thumbnail = b.thumbnail || '';
  formState.has_openai_api_key = b.has_openai_api_key || false;
  formState.has_google_api_key = b.has_google_api_key || false;
  formState.openai_api_key = '';
  formState.google_api_key = '';

  const ac = b.assistant_config || {};
  Object.assign(formState.assistant_config, defaultAssistantConfig(), ac);

  const abc = b.agent_behavior_config || {};
  const defaults = defaultBehaviorConfig();
  formState.agent_behavior_config.industry_sector_type =
    abc.industry_sector_type ?? defaults.industry_sector_type;

  if (abc.response) Object.assign(formState.agent_behavior_config.response, abc.response);
  if (abc.modules) {
    Object.keys(abc.modules).forEach(key => {
      if (formState.agent_behavior_config.modules[key]) {
        Object.assign(formState.agent_behavior_config.modules[key], abc.modules[key]);
      } else {
        formState.agent_behavior_config.modules[key] = abc.modules[key];
      }
    });
  }
  if (abc.tools) {
    Object.keys(abc.tools).forEach(key => {
      if (formState.agent_behavior_config.tools[key]) {
        Object.assign(formState.agent_behavior_config.tools[key], abc.tools[key]);
      } else {
        formState.agent_behavior_config.tools[key] = abc.tools[key];
      }
    });
  }
  if (abc.lead_warming) Object.assign(formState.agent_behavior_config.lead_warming, abc.lead_warming);
  if (abc.module_fallbacks) Object.assign(formState.agent_behavior_config.module_fallbacks, abc.module_fallbacks);
  if (abc.qualification_questions) formState.agent_behavior_config.qualification_questions = [...abc.qualification_questions];
  if (abc.additional_instructions !== undefined) formState.agent_behavior_config.additional_instructions = abc.additional_instructions;
  if (abc.proactive_reengagement) {
    const pr = abc.proactive_reengagement;
    const def = formState.agent_behavior_config.proactive_reengagement;
    def.enabled = pr.enabled ?? def.enabled;
    if (pr.attempts?.length) def.attempts = pr.attempts;
    if (pr.stop_conditions) Object.assign(def.stop_conditions, pr.stop_conditions);
    if (pr.stop_keywords) Object.assign(def.stop_keywords, pr.stop_keywords);
    if (pr.reactivation) Object.assign(def.reactivation, pr.reactivation);
  }
};

watch(bot, initForm, { deep: true });

const onTabChange = index => {
  selectedTabIndex.value = index;
};

const handleSave = async () => {
  const data = {
    name: formState.name,
    description: formState.description,
    outgoing_url: formState.outgoing_url,
    assistant_config: formState.assistant_config,
    agent_behavior_config: formState.agent_behavior_config,
  };
  if (formState.openai_api_key) data.openai_api_key = formState.openai_api_key;
  if (formState.google_api_key) data.google_api_key = formState.google_api_key;

  const result = await store.dispatch('agentBots/updateConfig', {
    id: botId.value,
    data,
  });
  if (result) useAlert(t('AGENT_BOTS.CONFIG.SUCCESS_MESSAGE'));
  else useAlert(t('AGENT_BOTS.CONFIG.ERROR_MESSAGE'));
};

onMounted(async () => {
  await store.dispatch('agentBots/show', botId.value);
  initForm();
});
</script>

<template>
  <div class="overflow-auto flex-grow flex-shrink w-full min-w-0">
    <SettingIntroBanner
      :header-image="formState.thumbnail"
      :header-title="formState.name"
      :back-url="{ name: 'ai_agents', params: { accountId: route.params.accountId } }"
    >
      <div class="flex items-center justify-between pr-1">
        <woot-tabs
          :index="selectedTabIndex"
          :border="false"
          @change="onTabChange"
        >
          <woot-tabs-item
            v-for="(tab, index) in tabs"
            :key="tab.key"
            :index="index"
            :name="tab.name"
            :show-badge="false"
            is-compact
          />
        </woot-tabs>
        <Button
          :label="$t('AGENT_BOTS.CONFIG.SAVE')"
          :is-loading="uiFlags.isUpdating"
          @click="handleSave"
        />
      </div>
    </SettingIntroBanner>

    <div
      v-if="uiFlags.isFetchingItem"
      class="flex items-center justify-center py-20"
    >
      <Spinner />
    </div>

    <section v-else class="mx-auto w-full max-w-6xl">
      <div class="mx-8">
        <TabGeneral v-if="selectedTabIndex === 0" :form="formState" />
        <TabAssistant v-else-if="selectedTabIndex === 1" :form="formState" />
        <TabModel v-else-if="selectedTabIndex === 2" :form="formState" />
        <TabCapabilities v-else-if="selectedTabIndex === 3" :form="formState" />
        <TabTools v-else-if="selectedTabIndex === 4" :form="formState" />
        <TabContent v-else-if="selectedTabIndex === 5" :form="formState" />
      </div>
    </section>
  </div>
</template>
