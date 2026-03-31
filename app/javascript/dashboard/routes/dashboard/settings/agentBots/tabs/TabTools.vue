<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import SettingsSection from 'dashboard/components/SettingsSection.vue';

const props = defineProps({
  form: { type: Object, required: true },
});

const { t } = useI18n();

const expanded = ref({});

const toggleExpand = key => {
  expanded.value[key] = !expanded.value[key];
};

const TOOLS = [
  { key: 'search_product_info', icon: '🔍', hasParams: true },
  { key: 'get_all_products', icon: '📦', hasParams: true },
  { key: 'get_faqs', icon: '❓', hasParams: true },
  { key: 'get_marketing_campaigns', icon: '🎯', hasParams: false },
  { key: 'get_kb_resources', icon: '📚', hasParams: false },
  { key: 'send_document', icon: '📎', hasParams: true },
  { key: 'transfer_chat', icon: '🤝', hasParams: false },
];

const getToolConfig = key =>
  props.form.agent_behavior_config.tools[key] || {};

const addExample = key => {
  const tool = getToolConfig(key);
  if (!tool.examples) tool.examples = [];
  if (tool.examples.length < 5) tool.examples.push('');
};

const removeExample = (key, index) => {
  getToolConfig(key).examples.splice(index, 1);
};

const updateExample = (key, index, value) => {
  getToolConfig(key).examples[index] = value;
};

const toggleAllowedType = (key, type) => {
  const tool = getToolConfig(key);
  if (!tool.allowed_types) tool.allowed_types = [];
  const idx = tool.allowed_types.indexOf(type);
  if (idx === -1) tool.allowed_types.push(type);
  else tool.allowed_types.splice(idx, 1);
};
</script>

<template>
  <SettingsSection
    :title="$t('AGENT_BOTS.CONFIG.TOOLS.SECTION_TITLE')"
    :sub-title="$t('AGENT_BOTS.CONFIG.TOOLS.SECTION_DESC')"
    :show-border="false"
  >
    <div
      class="flex flex-col border border-n-weak rounded-xl overflow-hidden divide-y divide-n-weak"
    >
      <div v-for="tool in TOOLS" :key="tool.key">
        <div class="p-4">
          <!-- Tool header -->
          <div class="flex items-start justify-between gap-4">
            <div class="flex items-start gap-3 flex-1 min-w-0">
              <input
                type="checkbox"
                :checked="getToolConfig(tool.key).enabled"
                class="accent-n-brand w-4 h-4 mt-0.5 shrink-0"
                @change="e => (getToolConfig(tool.key).enabled = e.target.checked)"
              />
              <div class="flex flex-col gap-0.5 min-w-0">
                <span class="text-sm font-medium text-n-slate-12">
                  {{ tool.icon }}
                  {{ $t(`AGENT_BOTS.CONFIG.TOOLS.TOOLS_LIST.${tool.key}.LABEL`) }}
                </span>
                <span class="text-xs text-n-slate-10 font-mono">
                  {{ tool.key }}_tool
                </span>
                <p class="text-xs text-n-slate-11 mt-0.5">
                  {{ $t(`AGENT_BOTS.CONFIG.TOOLS.TOOLS_LIST.${tool.key}.DESC`) }}
                </p>
              </div>
            </div>
            <button
              type="button"
              class="text-xs text-n-slate-10 hover:text-n-brand shrink-0 flex items-center gap-1"
              @click="toggleExpand(tool.key)"
            >
              <span>
                {{
                  expanded[tool.key]
                    ? $t('AGENT_BOTS.CONFIG.TOOLS.COLLAPSE')
                    : $t('AGENT_BOTS.CONFIG.TOOLS.EXPAND')
                }}
              </span>
              <span
                class="i-lucide-chevron-down transition-transform"
                :class="{ 'rotate-180': expanded[tool.key] }"
              />
            </button>
          </div>

          <!-- Expanded content -->
          <div v-if="expanded[tool.key]" class="mt-4 flex flex-col gap-4">
            <div class="grid grid-cols-2 gap-4">
              <!-- Params column -->
              <div class="flex flex-col gap-3">
                <span
                  class="text-xs font-semibold text-n-slate-11 uppercase tracking-wide"
                >
                  {{ $t('AGENT_BOTS.CONFIG.TOOLS.PARAMS_LABEL') }}
                </span>

                <template v-if="tool.key === 'search_product_info'">
                  <div class="flex flex-col gap-1">
                    <label class="text-xs text-n-slate-11">
                      {{ $t('AGENT_BOTS.CONFIG.TOOLS.TOOLS_LIST.search_product_info.THRESHOLD_LABEL') }}
                    </label>
                    <div class="flex items-center gap-2">
                      <input
                        type="range"
                        min="0"
                        max="1"
                        step="0.05"
                        :value="getToolConfig(tool.key).score_threshold ?? 0.75"
                        class="flex-1 accent-n-brand"
                        @input="e => (getToolConfig(tool.key).score_threshold = parseFloat(e.target.value))"
                      />
                      <span class="text-xs font-mono text-n-slate-12 w-8 text-right">
                        {{ getToolConfig(tool.key).score_threshold ?? 0.75 }}
                      </span>
                    </div>
                  </div>
                  <div class="flex items-center gap-2">
                    <label class="text-xs text-n-slate-11 shrink-0">
                      {{ $t('AGENT_BOTS.CONFIG.TOOLS.TOOLS_LIST.search_product_info.TOPK_LABEL') }}
                    </label>
                    <input
                      type="number"
                      :value="getToolConfig(tool.key).top_k ?? 10"
                      min="1"
                      max="50"
                      class="w-16 px-2 py-1 text-sm rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand text-center"
                      @input="e => (getToolConfig(tool.key).top_k = parseInt(e.target.value))"
                    />
                  </div>
                </template>

                <template v-else-if="tool.key === 'get_all_products'">
                  <div class="flex flex-col gap-1">
                    <label class="text-xs text-n-slate-11">
                      {{ $t('AGENT_BOTS.CONFIG.TOOLS.TOOLS_LIST.get_all_products.MODE_LABEL') }}
                    </label>
                    <label
                      v-for="mode in ['all', 'limited', 'summary']"
                      :key="mode"
                      class="flex items-center gap-2 text-xs text-n-slate-12 cursor-pointer"
                    >
                      <input
                        type="radio"
                        :value="mode"
                        :checked="getToolConfig(tool.key).listing_mode === mode"
                        class="accent-n-brand"
                        @change="getToolConfig(tool.key).listing_mode = mode"
                      />
                      {{ $t(`AGENT_BOTS.CONFIG.TOOLS.TOOLS_LIST.get_all_products.MODE_${mode.toUpperCase()}`) }}
                      <input
                        v-if="mode === 'limited' && getToolConfig(tool.key).listing_mode === 'limited'"
                        type="number"
                        :value="getToolConfig(tool.key).max_results || 5"
                        min="1"
                        class="w-14 px-2 py-0.5 text-xs rounded border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-1 focus:ring-n-brand text-center"
                        @input="e => (getToolConfig(tool.key).max_results = parseInt(e.target.value))"
                      />
                    </label>
                  </div>
                  <label class="flex items-center gap-2 text-xs text-n-slate-12 cursor-pointer">
                    <input
                      type="checkbox"
                      :checked="getToolConfig(tool.key).show_prices_by_default"
                      class="accent-n-brand"
                      @change="e => (getToolConfig(tool.key).show_prices_by_default = e.target.checked)"
                    />
                    {{ $t('AGENT_BOTS.CONFIG.TOOLS.TOOLS_LIST.get_all_products.PRICES_LABEL') }}
                  </label>
                </template>

                <template v-else-if="tool.key === 'get_faqs'">
                  <div class="flex items-center gap-2">
                    <label class="text-xs text-n-slate-11 shrink-0">
                      {{ $t('AGENT_BOTS.CONFIG.TOOLS.TOOLS_LIST.get_faqs.PER_PAGE_LABEL') }}
                    </label>
                    <input
                      type="number"
                      :value="getToolConfig(tool.key).per_page ?? 8"
                      min="1"
                      max="20"
                      class="w-16 px-2 py-1 text-sm rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand text-center"
                      @input="e => (getToolConfig(tool.key).per_page = parseInt(e.target.value))"
                    />
                  </div>
                </template>

                <template v-else-if="tool.key === 'send_document'">
                  <div class="flex flex-col gap-1">
                    <label class="text-xs text-n-slate-11">
                      {{ $t('AGENT_BOTS.CONFIG.TOOLS.TOOLS_LIST.send_document.SOURCE_LABEL') }}
                    </label>
                    <label
                      v-for="src in [
                        { value: 'catalog', label: 'SOURCE_CATALOG' },
                        { value: 'both', label: 'SOURCE_API' },
                      ]"
                      :key="src.value"
                      class="flex items-center gap-2 text-xs text-n-slate-12 cursor-pointer"
                    >
                      <input
                        type="radio"
                        :value="src.value"
                        :checked="
                          src.value === 'both'
                            ? (getToolConfig(tool.key).sources || []).includes('nauto_api')
                            : !(getToolConfig(tool.key).sources || []).includes('nauto_api')
                        "
                        class="accent-n-brand"
                        @change="
                          getToolConfig(tool.key).sources =
                            src.value === 'both'
                              ? ['catalog', 'nauto_api']
                              : ['catalog']
                        "
                      />
                      {{ $t(`AGENT_BOTS.CONFIG.TOOLS.TOOLS_LIST.send_document.${src.label}`) }}
                    </label>
                  </div>
                  <div class="flex flex-col gap-1">
                    <label class="text-xs text-n-slate-11">
                      {{ $t('AGENT_BOTS.CONFIG.TOOLS.TOOLS_LIST.send_document.TYPES_LABEL') }}
                    </label>
                    <label
                      v-for="type in ['pdf', 'image', 'video']"
                      :key="type"
                      class="flex items-center gap-2 text-xs text-n-slate-12 cursor-pointer"
                    >
                      <input
                        type="checkbox"
                        :checked="(getToolConfig(tool.key).allowed_types || []).includes(type)"
                        class="accent-n-brand"
                        @change="toggleAllowedType(tool.key, type)"
                      />
                      {{ $t(`AGENT_BOTS.CONFIG.TOOLS.TOOLS_LIST.send_document.TYPE_${type.toUpperCase()}`) }}
                    </label>
                  </div>
                </template>

                <template v-else>
                  <p class="text-xs text-n-slate-10 italic">
                    {{ $t(`AGENT_BOTS.CONFIG.TOOLS.TOOLS_LIST.${tool.key}.NO_PARAMS`) }}
                  </p>
                </template>
              </div>

              <!-- Examples column -->
              <div class="flex flex-col gap-2">
                <div class="flex items-center gap-1">
                  <span
                    class="text-xs font-semibold text-n-slate-11 uppercase tracking-wide"
                  >
                    {{ $t('AGENT_BOTS.CONFIG.TOOLS.EXAMPLES_LABEL') }}
                  </span>
                  <span class="text-xs text-n-slate-9">
                    {{ $t('AGENT_BOTS.CONFIG.TOOLS.EXAMPLES_MAX') }}
                  </span>
                </div>
                <p class="text-xs text-n-slate-10">
                  {{ $t('AGENT_BOTS.CONFIG.TOOLS.EXAMPLES_HINT') }}
                </p>
                <div class="flex flex-col gap-1.5">
                  <div
                    v-for="(example, idx) in getToolConfig(tool.key).examples || []"
                    :key="idx"
                    class="flex items-center gap-1"
                  >
                    <input
                      type="text"
                      :value="example"
                      class="flex-1 px-2 py-1 text-xs rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-1 focus:ring-n-brand"
                      @input="e => updateExample(tool.key, idx, e.target.value)"
                    />
                    <button
                      type="button"
                      class="text-n-slate-9 hover:text-ruby-800 shrink-0"
                      @click="removeExample(tool.key, idx)"
                    >
                      <span class="i-lucide-x w-3.5 h-3.5" />
                    </button>
                  </div>
                  <button
                    v-if="(getToolConfig(tool.key).examples || []).length < 5"
                    type="button"
                    class="text-xs text-n-brand hover:underline text-left"
                    @click="addExample(tool.key)"
                  >
                    {{ $t('AGENT_BOTS.CONFIG.TOOLS.EXAMPLES_ADD') }}
                  </button>
                </div>
              </div>
            </div>

            <!-- Custom instructions -->
            <div class="flex flex-col gap-1">
              <label
                class="text-xs font-semibold text-n-slate-11 uppercase tracking-wide"
              >
                {{ $t('AGENT_BOTS.CONFIG.TOOLS.INSTRUCTIONS_LABEL') }}
              </label>
              <textarea
                :value="getToolConfig(tool.key).custom_instructions"
                rows="2"
                class="w-full px-3 py-2 text-xs rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand resize-none"
                :placeholder="$t('AGENT_BOTS.CONFIG.TOOLS.INSTRUCTIONS_PLACEHOLDER')"
                @input="e => (getToolConfig(tool.key).custom_instructions = e.target.value)"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  </SettingsSection>
</template>
