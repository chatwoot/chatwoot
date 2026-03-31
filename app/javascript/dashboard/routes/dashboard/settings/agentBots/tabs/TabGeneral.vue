<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';

import SettingsSection from 'dashboard/components/SettingsSection.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

const props = defineProps({
  form: { type: Object, required: true },
});

const { t } = useI18n();

const PREDEFINED_INDUSTRIES = [
  { key: 'automotive', label: t('AGENT_BOTS.CONFIG.GENERAL.INDUSTRIES.automotive') },
  { key: 'health', label: t('AGENT_BOTS.CONFIG.GENERAL.INDUSTRIES.health') },
  { key: 'retail', label: t('AGENT_BOTS.CONFIG.GENERAL.INDUSTRIES.retail') },
  { key: 'restaurant', label: t('AGENT_BOTS.CONFIG.GENERAL.INDUSTRIES.restaurant') },
  { key: 'legal', label: t('AGENT_BOTS.CONFIG.GENERAL.INDUSTRIES.legal') },
  { key: 'financial', label: t('AGENT_BOTS.CONFIG.GENERAL.INDUSTRIES.financial') },
  { key: 'real_estate', label: t('AGENT_BOTS.CONFIG.GENERAL.INDUSTRIES.real_estate') },
  { key: 'education', label: t('AGENT_BOTS.CONFIG.GENERAL.INDUSTRIES.education') },
];

const industrySearch = ref('');

const filteredIndustries = computed(() => {
  const q = industrySearch.value.toLowerCase();
  return q
    ? PREDEFINED_INDUSTRIES.filter(i => i.label.toLowerCase().includes(q))
    : PREDEFINED_INDUSTRIES;
});

const showCreateOption = computed(() => {
  const q = industrySearch.value.trim();
  return (
    q &&
    !PREDEFINED_INDUSTRIES.some(i => i.label.toLowerCase() === q.toLowerCase())
  );
});

const selectIndustry = key => {
  props.form.agent_behavior_config.industry_sector_type = key;
  industrySearch.value = '';
};

const createCustomIndustry = () => {
  props.form.agent_behavior_config.industry_sector_type =
    industrySearch.value.trim();
  industrySearch.value = '';
};

const currentIndustryLabel = computed(() => {
  const found = PREDEFINED_INDUSTRIES.find(
    i => i.key === props.form.agent_behavior_config.industry_sector_type
  );
  return found
    ? found.label
    : props.form.agent_behavior_config.industry_sector_type;
});
</script>

<template>
  <div>
    <SettingsSection
      :title="$t('AGENT_BOTS.CONFIG.GENERAL.SECTION_IDENTITY')"
      :sub-title="$t('AGENT_BOTS.CONFIG.GENERAL.SECTION_IDENTITY_DESC')"
    >
      <div class="flex flex-col gap-4">
        <Input
          v-model="form.name"
          :label="$t('AGENT_BOTS.CONFIG.GENERAL.NAME_LABEL')"
          :placeholder="$t('AGENT_BOTS.CONFIG.GENERAL.NAME_PLACEHOLDER')"
        />
        <TextArea
          v-model="form.description"
          :label="$t('AGENT_BOTS.CONFIG.GENERAL.DESCRIPTION_LABEL')"
          :placeholder="$t('AGENT_BOTS.CONFIG.GENERAL.DESCRIPTION_PLACEHOLDER')"
          :rows="4"
        />
        <p class="text-xs text-n-slate-11 -mt-2">
          {{ $t('AGENT_BOTS.CONFIG.GENERAL.DESCRIPTION_HINT') }}
        </p>
        <Input
          v-model="form.outgoing_url"
          :label="$t('AGENT_BOTS.CONFIG.GENERAL.WEBHOOK_LABEL')"
          :placeholder="$t('AGENT_BOTS.CONFIG.GENERAL.WEBHOOK_PLACEHOLDER')"
        />
      </div>
    </SettingsSection>

    <SettingsSection
      :title="$t('AGENT_BOTS.CONFIG.GENERAL.SECTION_INDUSTRY')"
      :sub-title="$t('AGENT_BOTS.CONFIG.GENERAL.SECTION_INDUSTRY_DESC')"
      :show-border="false"
    >
      <div class="flex flex-col gap-3">
        <div
          v-if="form.agent_behavior_config.industry_sector_type"
          class="flex items-center gap-2"
        >
          <span class="text-sm font-medium text-n-slate-12">
            {{ currentIndustryLabel }}
          </span>
          <button
            type="button"
            class="text-xs text-n-brand hover:underline"
            @click="form.agent_behavior_config.industry_sector_type = ''"
          >
            {{ $t('AGENT_BOTS.FORM.CANCEL') }}
          </button>
        </div>

        <input
          v-model="industrySearch"
          type="text"
          class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-background text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-brand"
          :placeholder="$t('AGENT_BOTS.CONFIG.GENERAL.INDUSTRY_PLACEHOLDER')"
        />

        <div class="flex flex-col gap-0.5">
          <label
            v-for="industry in filteredIndustries"
            :key="industry.key"
            class="flex items-center gap-2 px-2 py-1.5 rounded-lg cursor-pointer hover:bg-n-alpha-1"
          >
            <input
              type="radio"
              :value="industry.key"
              :checked="
                form.agent_behavior_config.industry_sector_type === industry.key
              "
              class="accent-n-brand"
              @change="selectIndustry(industry.key)"
            />
            <span class="text-sm text-n-slate-12">{{ industry.label }}</span>
          </label>

          <button
            v-if="showCreateOption"
            type="button"
            class="flex items-center gap-2 px-2 py-1.5 rounded-lg text-sm text-n-brand hover:bg-n-alpha-1 text-left"
            @click="createCustomIndustry"
          >
            {{
              $t('AGENT_BOTS.CONFIG.GENERAL.INDUSTRY_CREATE', {
                value: industrySearch.trim(),
              })
            }}
          </button>
        </div>

        <p class="text-xs text-n-slate-11">
          {{ $t('AGENT_BOTS.CONFIG.GENERAL.INDUSTRY_HINT') }}
        </p>
      </div>
    </SettingsSection>
  </div>
</template>
