<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Accordion from 'dashboard/components-next/Accordion/Accordion.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';
import Label from 'dashboard/components-next/label/Label.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import AddNewRulesInput from 'dashboard/components-next/captain/assistant/AddNewRulesInput.vue';

const props = defineProps({
  session: { type: Object, required: true },
});

const { t } = useI18n();
const KNOWLEDGE_MAX_LENGTH = 10_000;

const RULE_TABS = {
  guidelines: {
    type: 'guideline',
    createTitle: 'CAPTAIN.PLAYGROUND.SETUP.GUIDELINES.CREATE_TITLE',
    createHint: 'CAPTAIN.PLAYGROUND.SETUP.GUIDELINES.CREATE_HINT',
    composerPlaceholder:
      'CAPTAIN.PLAYGROUND.SETUP.GUIDELINES.COMPOSER_PLACEHOLDER',
    fieldLabel: 'CAPTAIN.PLAYGROUND.SETUP.GUIDELINES.PLACEHOLDER',
    remove: 'CAPTAIN.PLAYGROUND.SETUP.GUIDELINES.REMOVE',
    addPermanently: 'CAPTAIN.PLAYGROUND.SETUP.GUIDELINES.ADD_PERMANENTLY',
    savedSummary: 'CAPTAIN.PLAYGROUND.SETUP.GUIDELINES.SAVED_SUMMARY',
    empty: 'CAPTAIN.PLAYGROUND.SETUP.GUIDELINES.EMPTY',
  },
  guardrails: {
    type: 'guardrail',
    createTitle: 'CAPTAIN.PLAYGROUND.SETUP.GUARDRAILS.CREATE_TITLE',
    createHint: 'CAPTAIN.PLAYGROUND.SETUP.GUARDRAILS.CREATE_HINT',
    composerPlaceholder:
      'CAPTAIN.PLAYGROUND.SETUP.GUARDRAILS.COMPOSER_PLACEHOLDER',
    fieldLabel: 'CAPTAIN.PLAYGROUND.SETUP.GUARDRAILS.PLACEHOLDER',
    remove: 'CAPTAIN.PLAYGROUND.SETUP.GUARDRAILS.REMOVE',
    addPermanently: 'CAPTAIN.PLAYGROUND.SETUP.GUARDRAILS.ADD_PERMANENTLY',
    savedSummary: 'CAPTAIN.PLAYGROUND.SETUP.GUARDRAILS.SAVED_SUMMARY',
    empty: 'CAPTAIN.PLAYGROUND.SETUP.GUARDRAILS.EMPTY',
  },
};

const activeTab = ref('knowledge');
const collapsedScenarioIds = ref(new Set());
const isKnowledgeEditorVisible = ref(Boolean(props.session.knowledgeText));
const drafts = reactive({
  knowledge: '',
  scenarios: '',
  guidelines: '',
  guardrails: '',
});

const tabs = computed(() => [
  {
    id: 'knowledge',
    label: t('CAPTAIN.PLAYGROUND.SETUP.KNOWLEDGE.TAB_TITLE'),
  },
  {
    id: 'scenarios',
    label: t('CAPTAIN.PLAYGROUND.SETUP.SCENARIOS.TAB_TITLE'),
  },
  {
    id: 'guidelines',
    label: t('CAPTAIN.PLAYGROUND.SETUP.GUIDELINES.TAB_TITLE'),
  },
  {
    id: 'guardrails',
    label: t('CAPTAIN.PLAYGROUND.SETUP.GUARDRAILS.TAB_TITLE'),
  },
]);

const activeTabIndex = computed(() =>
  tabs.value.findIndex(tab => tab.id === activeTab.value)
);

const activeRuleTab = computed(() => RULE_TABS[activeTab.value]);

const temporaryRules = computed(() =>
  activeRuleTab.value?.type === 'guideline'
    ? props.session.temporaryGuidelines
    : props.session.temporaryGuardrails
);

const savedRules = computed(() =>
  activeRuleTab.value?.type === 'guideline'
    ? props.session.savedGuidelines
    : props.session.savedGuardrails
);

const savedRuleTitle = computed(() =>
  activeRuleTab.value
    ? t(activeRuleTab.value.savedSummary, { count: savedRules.value.length })
    : ''
);

const savedScenarioTitle = computed(() =>
  t('CAPTAIN.PLAYGROUND.SETUP.SCENARIOS.SAVED_SUMMARY', {
    count: props.session.savedScenarios.length,
  })
);

const includedScenarioIdSet = computed(
  () => new Set(props.session.includedScenarioIds)
);

const toggleRule = rule => {
  rule.included = !rule.included;
};

const addTemporaryRule = content => {
  props.session.addTemporaryRule(activeRuleTab.value.type, content);
};

const isTemporaryScenarioCollapsed = scenario =>
  collapsedScenarioIds.value.has(scenario.clientId);

const temporaryScenarioToggleLabel = scenario => {
  if (isTemporaryScenarioCollapsed(scenario)) {
    return t('CAPTAIN.PLAYGROUND.SETUP.SCENARIOS.EXPAND');
  }

  return t('CAPTAIN.PLAYGROUND.SETUP.SCENARIOS.COLLAPSE');
};

const toggleTemporaryScenario = scenario => {
  const nextCollapsedScenarioIds = new Set(collapsedScenarioIds.value);
  if (nextCollapsedScenarioIds.has(scenario.clientId)) {
    nextCollapsedScenarioIds.delete(scenario.clientId);
  } else {
    nextCollapsedScenarioIds.add(scenario.clientId);
  }
  collapsedScenarioIds.value = nextCollapsedScenarioIds;
};

const addTemporaryKnowledge = content => {
  const normalizedContent = content?.trim();
  if (!normalizedContent) return;

  props.session.setKnowledgeText(normalizedContent);
  isKnowledgeEditorVisible.value = true;
};

const selectTab = tab => {
  activeTab.value = tab.id;
};
</script>

<template>
  <section class="flex min-h-0 flex-col text-n-slate-12">
    <div
      v-if="session.isInitializing"
      class="flex flex-1 items-center justify-center py-10"
    >
      <Spinner />
    </div>
    <template v-else>
      <div class="border-b border-n-weak pb-3 xl:px-4 xl:pt-3">
        <div data-testid="playground-setup-tabs" class="min-w-0">
          <TabBar
            :tabs="tabs"
            :initial-active-tab="activeTabIndex"
            class="!w-full [&>button]:min-w-0 [&>button]:flex-1 [&>button]:px-2"
            @tab-changed="selectTab"
          />
        </div>
      </div>

      <div class="flex-1 overflow-y-auto pt-4 xl:p-4">
        <div
          v-if="session.loadError"
          role="alert"
          class="mb-4 flex items-start gap-2 rounded-lg border border-n-ruby-7 bg-n-ruby-3 p-3 text-sm text-n-ruby-11"
        >
          <Icon icon="i-lucide-circle-alert" class="mt-0.5 size-4 shrink-0" />
          <span>{{ session.loadError }}</span>
        </div>

        <section v-if="activeTab === 'scenarios'" class="flex flex-col gap-4">
          <div class="min-w-0">
            <h4 class="text-sm font-medium">
              {{ t('CAPTAIN.PLAYGROUND.SETUP.SCENARIOS.CREATE_TITLE') }}
            </h4>
            <p class="mt-1 text-xs leading-5 text-n-slate-11">
              {{ t('CAPTAIN.PLAYGROUND.SETUP.SCENARIOS.CREATE_HINT') }}
            </p>
          </div>

          <AddNewRulesInput
            v-model="drafts.scenarios"
            :placeholder="
              t('CAPTAIN.PLAYGROUND.SETUP.SCENARIOS.COMPOSER_PLACEHOLDER')
            "
            :label="t('CAPTAIN.PLAYGROUND.SETUP.ADD_TO_TEST')"
            @add="session.addTemporaryScenario"
          />

          <div
            v-for="scenario in session.temporaryScenarios"
            :key="scenario.clientId"
            class="overflow-hidden rounded-xl border border-n-strong bg-n-solid-2"
          >
            <div class="flex min-h-16 items-center gap-3 px-4 py-3">
              <Icon
                icon="i-lucide-workflow"
                class="size-5 shrink-0 text-n-slate-10"
              />
              <InlineInput
                :id="`temporary-scenario-title-${scenario.clientId}`"
                v-model="scenario.title"
                :label="
                  t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.LABEL')
                "
                custom-label-class="sr-only"
                :placeholder="
                  t(
                    'CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.PLACEHOLDER'
                  )
                "
              />
              <div class="flex shrink-0 items-center gap-1">
                <Label
                  :label="t('CAPTAIN.PLAYGROUND.SETUP.SESSION_ONLY')"
                  compact
                  color="amber"
                />
                <Button
                  icon="i-lucide-trash-2"
                  variant="ghost"
                  color="ruby"
                  size="xs"
                  :aria-label="t('CAPTAIN.PLAYGROUND.SETUP.SCENARIOS.REMOVE')"
                  @click="session.removeTemporaryScenario(scenario.clientId)"
                />
                <Button
                  :icon="
                    isTemporaryScenarioCollapsed(scenario)
                      ? 'i-lucide-chevron-down'
                      : 'i-lucide-chevron-up'
                  "
                  variant="ghost"
                  color="slate"
                  size="xs"
                  :aria-label="temporaryScenarioToggleLabel(scenario)"
                  :aria-expanded="!isTemporaryScenarioCollapsed(scenario)"
                  :aria-controls="`temporary-scenario-${scenario.clientId}`"
                  @click="toggleTemporaryScenario(scenario)"
                />
              </div>
            </div>
            <div
              v-if="!isTemporaryScenarioCollapsed(scenario)"
              :id="`temporary-scenario-${scenario.clientId}`"
              class="flex flex-col gap-3 border-t border-n-weak p-4"
            >
              <TextArea
                v-model="scenario.description"
                :max-length="500"
                show-character-count
                :label="
                  t(
                    'CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.DESCRIPTION.LABEL'
                  )
                "
              />
              <Editor
                v-model="scenario.instruction"
                :label="
                  t(
                    'CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.INSTRUCTION.LABEL'
                  )
                "
                :show-character-count="false"
                enable-captain-tools
              />
              <div
                class="flex flex-wrap items-center justify-between gap-3 border-t border-n-weak pt-3"
              >
                <Button
                  v-if="session.isAdmin"
                  :label="
                    t('CAPTAIN.PLAYGROUND.SETUP.SCENARIOS.ADD_PERMANENTLY')
                  "
                  variant="outline"
                  color="slate"
                  size="sm"
                  class="!-outline-offset-1"
                  :disabled="!session.scenarioIsValid(scenario)"
                  :is-loading="scenario.isSaving"
                  @click="session.saveTemporaryScenario(scenario)"
                />
                <span v-else />
                <label
                  class="flex cursor-pointer items-center gap-2 text-xs font-medium text-n-slate-12"
                >
                  {{ t('CAPTAIN.PLAYGROUND.SETUP.INCLUDE_IN_TEST') }}
                  <Checkbox v-model="scenario.included" />
                </label>
              </div>
            </div>
          </div>

          <Accordion :title="savedScenarioTitle" class="bg-n-solid-1">
            <div
              v-if="session.savedScenarios.length"
              class="flex max-h-72 flex-col gap-0.5 overflow-y-auto rounded-lg border border-n-weak bg-n-solid-1 p-1"
            >
              <label
                v-for="scenario in session.savedScenarios"
                :key="scenario.id"
                class="flex cursor-pointer items-start gap-3 rounded-md p-2 transition-colors hover:bg-n-alpha-2"
              >
                <Checkbox
                  :model-value="includedScenarioIdSet.has(scenario.id)"
                  class="mt-0.5 shrink-0"
                  @update:model-value="session.toggleScenario(scenario.id)"
                />
                <span class="min-w-0 flex-1">
                  <span
                    class="flex flex-wrap items-center gap-2 text-sm font-medium"
                  >
                    {{ scenario.title }}
                    <Label
                      v-if="!scenario.enabled"
                      :label="t('CAPTAIN.PLAYGROUND.SETUP.SCENARIOS.DISABLED')"
                      compact
                    />
                  </span>
                  <span
                    v-if="scenario.description"
                    class="mt-1 line-clamp-2 block text-xs leading-5 text-n-slate-11"
                  >
                    {{ scenario.description }}
                  </span>
                </span>
              </label>
            </div>
            <p
              v-else
              class="rounded-lg border border-dashed border-n-weak p-3 text-center text-xs text-n-slate-11"
            >
              {{ t('CAPTAIN.PLAYGROUND.SETUP.SCENARIOS.EMPTY') }}
            </p>
          </Accordion>
        </section>

        <section
          v-else-if="activeRuleTab"
          :key="activeTab"
          class="flex flex-col gap-4"
        >
          <div class="min-w-0">
            <h4 class="text-sm font-medium">
              {{ t(activeRuleTab.createTitle) }}
            </h4>
            <p class="mt-1 text-xs leading-5 text-n-slate-11">
              {{ t(activeRuleTab.createHint) }}
            </p>
          </div>

          <AddNewRulesInput
            v-model="drafts[activeTab]"
            :placeholder="t(activeRuleTab.composerPlaceholder)"
            :label="t('CAPTAIN.PLAYGROUND.SETUP.ADD_TO_TEST')"
            @add="addTemporaryRule"
          />

          <div
            v-for="rule in temporaryRules"
            :key="rule.clientId"
            class="flex flex-col gap-3 rounded-xl border border-n-strong bg-n-solid-2 p-4"
          >
            <div class="flex items-center justify-between gap-3">
              <Label
                :label="t('CAPTAIN.PLAYGROUND.SETUP.SESSION_ONLY')"
                compact
                color="amber"
              />
              <Button
                icon="i-lucide-trash-2"
                variant="ghost"
                color="ruby"
                size="xs"
                :aria-label="t(activeRuleTab.remove)"
                @click="
                  session.removeTemporaryRule(activeRuleTab.type, rule.clientId)
                "
              />
            </div>
            <Input
              v-model="rule.content"
              :label="t(activeRuleTab.fieldLabel)"
              :placeholder="t(activeRuleTab.fieldLabel)"
            />
            <div
              class="flex flex-wrap items-center justify-between gap-3 border-t border-n-weak pt-3"
            >
              <Button
                v-if="session.isAdmin"
                :label="t(activeRuleTab.addPermanently)"
                variant="outline"
                color="slate"
                size="sm"
                class="!-outline-offset-1"
                :disabled="
                  !rule.content.trim() ||
                  session.isRuleTypeSaving(activeRuleTab.type)
                "
                :is-loading="rule.isSaving"
                @click="session.saveTemporaryRule(activeRuleTab.type, rule)"
              />
              <span v-else />
              <label
                class="flex cursor-pointer items-center gap-2 text-xs font-medium text-n-slate-12"
              >
                {{ t('CAPTAIN.PLAYGROUND.SETUP.INCLUDE_IN_TEST') }}
                <Checkbox v-model="rule.included" />
              </label>
            </div>
          </div>

          <Accordion :title="savedRuleTitle" class="bg-n-solid-1">
            <div
              v-if="savedRules.length"
              class="flex max-h-72 flex-col gap-0.5 overflow-y-auto rounded-lg border border-n-weak bg-n-solid-1 p-1"
            >
              <label
                v-for="rule in savedRules"
                :key="rule.key"
                class="flex cursor-pointer items-start gap-3 rounded-md p-2 transition-colors hover:bg-n-alpha-2"
              >
                <Checkbox
                  :model-value="rule.included"
                  class="mt-0.5 shrink-0"
                  @update:model-value="toggleRule(rule)"
                />
                <span class="text-sm leading-5">{{ rule.content }}</span>
              </label>
            </div>
            <p
              v-else
              class="rounded-lg border border-dashed border-n-weak p-3 text-center text-xs text-n-slate-11"
            >
              {{ t(activeRuleTab.empty) }}
            </p>
          </Accordion>
        </section>

        <section v-else class="flex flex-col gap-5">
          <div
            class="grid grid-cols-[minmax(0,1fr)_auto_auto] items-center gap-3 rounded-xl border border-n-blue-4 bg-n-blue-2 p-4"
          >
            <div class="flex min-w-0 items-start gap-3">
              <span
                class="grid size-8 shrink-0 place-content-center rounded-full bg-n-blue-3 text-n-blue-11"
              >
                <Icon icon="i-lucide-library-big" class="size-4" />
              </span>
              <div class="min-w-0">
                <h4 class="text-sm font-medium">
                  {{ t('CAPTAIN.PLAYGROUND.SETUP.KNOWLEDGE.AVAILABLE_TITLE') }}
                </h4>
                <p class="mt-1 text-xs leading-5 text-n-slate-11">
                  {{
                    t(
                      'CAPTAIN.PLAYGROUND.SETUP.KNOWLEDGE.AVAILABLE_DESCRIPTION'
                    )
                  }}
                </p>
              </div>
            </div>
            <div class="min-w-16 border-s border-n-blue-4 ps-3 text-center">
              <strong class="block text-lg font-medium text-n-slate-12">
                {{ session.knowledgeStats.documents }}
              </strong>
              <span class="text-xs text-n-slate-11">
                {{ t('CAPTAIN.PLAYGROUND.SETUP.KNOWLEDGE.DOCUMENTS') }}
              </span>
            </div>
            <div class="min-w-16 text-center">
              <strong class="block text-lg font-medium text-n-slate-12">
                {{ session.knowledgeStats.faqs }}
              </strong>
              <span class="text-xs text-n-slate-11">
                {{ t('CAPTAIN.PLAYGROUND.SETUP.KNOWLEDGE.FAQS') }}
              </span>
            </div>
          </div>

          <div class="flex flex-col gap-3">
            <div class="flex items-start justify-between gap-3">
              <div>
                <h4 class="text-sm font-medium">
                  {{ t('CAPTAIN.PLAYGROUND.SETUP.KNOWLEDGE.TEMPORARY_TITLE') }}
                </h4>
                <p class="mt-1 text-xs leading-5 text-n-slate-11">
                  {{ t('CAPTAIN.PLAYGROUND.SETUP.KNOWLEDGE.HINT') }}
                </p>
              </div>
              <Label
                :label="t('CAPTAIN.PLAYGROUND.SETUP.SESSION_ONLY')"
                compact
                color="amber"
              />
            </div>

            <AddNewRulesInput
              v-if="!isKnowledgeEditorVisible"
              v-model="drafts.knowledge"
              :placeholder="
                t('CAPTAIN.PLAYGROUND.SETUP.KNOWLEDGE.COMPOSER_PLACEHOLDER')
              "
              :label="t('CAPTAIN.PLAYGROUND.SETUP.ADD_TO_TEST')"
              :max-length="KNOWLEDGE_MAX_LENGTH"
              @add="addTemporaryKnowledge"
            />

            <div v-else class="flex flex-col gap-3">
              <TextArea
                :model-value="session.knowledgeText"
                :label="t('CAPTAIN.PLAYGROUND.SETUP.KNOWLEDGE.LABEL')"
                :placeholder="
                  t('CAPTAIN.PLAYGROUND.SETUP.KNOWLEDGE.PLACEHOLDER')
                "
                :max-length="KNOWLEDGE_MAX_LENGTH"
                show-character-count
                resize
                @update:model-value="session.setKnowledgeText"
              />
              <div
                class="flex flex-wrap items-center justify-between gap-3 border-t border-n-weak pt-3"
              >
                <Button
                  v-if="session.isAdmin"
                  :label="
                    t('CAPTAIN.PLAYGROUND.SETUP.KNOWLEDGE.ADD_PERMANENTLY')
                  "
                  variant="outline"
                  class="!-outline-offset-1"
                  color="slate"
                  size="sm"
                  :disabled="
                    !session.knowledgeText.trim() || session.isSavingKnowledge
                  "
                  :is-loading="session.isSavingKnowledge"
                  @click="session.saveKnowledgeAsDocument"
                />
                <span v-else />
                <label
                  class="flex cursor-pointer items-center gap-2 text-xs font-medium text-n-slate-12"
                >
                  {{ t('CAPTAIN.PLAYGROUND.SETUP.INCLUDE_IN_TEST') }}
                  <Checkbox
                    :model-value="session.isKnowledgeIncluded"
                    @update:model-value="session.setKnowledgeIncluded"
                  />
                </label>
              </div>
            </div>
          </div>
        </section>
      </div>
    </template>
  </section>
</template>
