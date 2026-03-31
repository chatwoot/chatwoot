<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import SettingsSection from 'dashboard/components/SettingsSection.vue';

const props = defineProps({
  form: { type: Object, required: true },
});

const { t } = useI18n();

const modules = computed(() => props.form.agent_behavior_config.modules);
const leadWarming = computed(() => props.form.agent_behavior_config.lead_warming);
const reengagement = computed(
  () => props.form.agent_behavior_config.proactive_reengagement
);

const DELAY_UNITS = ['minutes', 'hours', 'days'];

const addAttempt = () => {
  const attempts = reengagement.value.attempts;
  if (attempts.length >= 5) return;
  attempts.push({ delay_value: 30, delay_unit: 'minutes' });
};

const removeAttempt = index => {
  reengagement.value.attempts.splice(index, 1);
};

const addKeyword = () => {
  reengagement.value.stop_keywords.phrases.push('');
};

const removeKeyword = index => {
  reengagement.value.stop_keywords.phrases.splice(index, 1);
};

const closingPhrasesText = computed({
  get() {
    return (leadWarming.value.closing_phrases || []).join('\n');
  },
  set(val) {
    leadWarming.value.closing_phrases = val
      .split('\n')
      .map(s => s.trim())
      .filter(Boolean);
  },
});

const appointmentFallback = computed(
  () =>
    props.form.agent_behavior_config.module_fallbacks?.appointments ||
    modules.value.appointments?.fallback ||
    {}
);

const FALLBACK_STRATEGIES = [
  {
    value: 'provide_phone',
    labelKey: 'AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.appointments.FALLBACK_PHONE',
  },
  {
    value: 'transfer_advisor',
    labelKey: 'AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.appointments.FALLBACK_TRANSFER',
  },
  {
    value: 'show_hours',
    labelKey: 'AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.appointments.FALLBACK_HOURS',
  },
  {
    value: 'custom_message',
    labelKey: 'AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.appointments.FALLBACK_CUSTOM',
  },
];
</script>

<template>
  <div>
    <SettingsSection
      :title="$t('AGENT_BOTS.CONFIG.CAPABILITIES.SECTION_MODULES')"
      :sub-title="$t('AGENT_BOTS.CONFIG.CAPABILITIES.MODULES_HINT')"
    >
      <div
        class="flex flex-col divide-y divide-n-weak border border-n-weak rounded-xl overflow-hidden"
      >
        <!-- General Response -->
        <div class="p-4 flex flex-col gap-1">
          <label class="flex items-center gap-3 cursor-pointer">
            <input
              v-model="modules.general_response.enabled"
              type="checkbox"
              class="accent-n-brand w-4 h-4"
            />
            <span class="text-sm font-medium text-n-slate-12">
              {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.general_response.LABEL') }}
            </span>
          </label>
          <p class="text-xs text-n-slate-11 ml-7">
            {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.general_response.DESC') }}
          </p>
        </div>

        <!-- Transfer Chat -->
        <div class="p-4 flex flex-col gap-1">
          <label class="flex items-center gap-3 cursor-pointer">
            <input
              v-model="modules.transfer_chat.enabled"
              type="checkbox"
              class="accent-n-brand w-4 h-4"
            />
            <span class="text-sm font-medium text-n-slate-12">
              {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.transfer_chat.LABEL') }}
            </span>
          </label>
          <p class="text-xs text-n-slate-11 ml-7">
            {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.transfer_chat.DESC') }}
          </p>
        </div>

        <!-- Appointments -->
        <div class="p-4 flex flex-col gap-3">
          <label class="flex items-center gap-3 cursor-pointer">
            <input
              v-model="modules.appointments.enabled"
              type="checkbox"
              class="accent-n-brand w-4 h-4"
            />
            <span class="text-sm font-medium text-n-slate-12">
              {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.appointments.LABEL') }}
            </span>
          </label>
          <p class="text-xs text-n-slate-11 ml-7">
            {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.appointments.DESC') }}
          </p>

          <div
            v-if="modules.appointments.enabled"
            class="ml-7 flex items-center gap-4"
          >
            <span class="text-xs text-n-slate-11">
              {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.appointments.ACTIONS_LABEL') }}:
            </span>
            <label
              v-for="action in ['create', 'reschedule', 'cancel']"
              :key="action"
              class="flex items-center gap-1.5 text-xs text-n-slate-12 cursor-pointer"
            >
              <input
                v-model="modules.appointments.actions[action]"
                type="checkbox"
                class="accent-n-brand"
              />
              {{ $t(`AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.appointments.ACTION_${action.toUpperCase()}`) }}
            </label>
          </div>

          <div
            v-if="!modules.appointments.enabled"
            class="ml-7 p-3 bg-n-amber-1 border border-n-amber-6 rounded-lg flex flex-col gap-3"
          >
            <p class="text-xs font-medium text-n-slate-12">
              {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.appointments.FALLBACK_TITLE') }}
            </p>
            <div class="flex flex-col gap-2">
              <label
                v-for="strategy in FALLBACK_STRATEGIES"
                :key="strategy.value"
                class="flex items-start gap-2 cursor-pointer"
              >
                <input
                  type="radio"
                  :value="strategy.value"
                  :checked="appointmentFallback.strategy === strategy.value"
                  class="accent-n-brand mt-0.5"
                  @change="appointmentFallback.strategy = strategy.value"
                />
                <span class="text-xs text-n-slate-12">{{ $t(strategy.labelKey) }}</span>
              </label>
            </div>
            <input
              v-if="appointmentFallback.strategy === 'provide_phone'"
              v-model="appointmentFallback.phone_number"
              type="text"
              class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
              :placeholder="$t('AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.appointments.FALLBACK_PHONE_PLACEHOLDER')"
            />
            <textarea
              v-if="appointmentFallback.strategy === 'custom_message'"
              v-model="appointmentFallback.custom_message"
              rows="2"
              class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand resize-none"
              :placeholder="$t('AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.appointments.FALLBACK_CUSTOM_PLACEHOLDER')"
            />
          </div>
        </div>

        <!-- Send Documents -->
        <div class="p-4 flex flex-col gap-3">
          <label class="flex items-center gap-3 cursor-pointer">
            <input
              v-model="modules.send_documents.enabled"
              type="checkbox"
              class="accent-n-brand w-4 h-4"
            />
            <span class="text-sm font-medium text-n-slate-12">
              {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.send_documents.LABEL') }}
            </span>
          </label>
          <p class="text-xs text-n-slate-11 ml-7">
            {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.send_documents.DESC') }}
          </p>
          <div v-if="modules.send_documents.enabled" class="ml-7 flex flex-col gap-1">
            <span class="text-xs text-n-slate-11 mb-1">
              {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.send_documents.TYPES_LABEL') }}:
            </span>
            <label
              v-for="type in ['pdf', 'image', 'video']"
              :key="type"
              class="flex items-center gap-1.5 text-xs text-n-slate-12 cursor-pointer"
            >
              <input
                type="checkbox"
                :checked="modules.send_documents.allowed_types?.includes(type)"
                class="accent-n-brand"
                @change="
                  e => {
                    const types = modules.send_documents.allowed_types || [];
                    modules.send_documents.allowed_types = e.target.checked
                      ? [...new Set([...types, type])]
                      : types.filter(t => t !== type);
                  }
                "
              />
              {{ $t(`AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.send_documents.TYPE_${type.toUpperCase()}`) }}
            </label>
          </div>
        </div>

        <!-- Out of Scope -->
        <div class="p-4 flex flex-col gap-3">
          <label class="flex items-center gap-3 cursor-pointer">
            <input
              v-model="modules.out_of_scope.enabled"
              type="checkbox"
              class="accent-n-brand w-4 h-4"
            />
            <span class="text-sm font-medium text-n-slate-12">
              {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.out_of_scope.LABEL') }}
            </span>
          </label>
          <p class="text-xs text-n-slate-11 ml-7">
            {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.out_of_scope.DESC') }}
          </p>
          <div
            v-if="modules.out_of_scope.enabled"
            class="ml-7 flex items-center gap-3"
          >
            <span class="text-xs text-n-slate-11">
              {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.MODULES.out_of_scope.ATTEMPTS_LABEL') }}:
            </span>
            <input
              v-model.number="modules.out_of_scope.max_attempts"
              type="number"
              min="1"
              max="10"
              class="w-16 px-2 py-1 text-sm rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand text-center"
            />
          </div>
        </div>
      </div>
    </SettingsSection>

    <SettingsSection
      :title="$t('AGENT_BOTS.CONFIG.CAPABILITIES.SECTION_LEAD_WARMING')"
      :sub-title="$t('AGENT_BOTS.CONFIG.CAPABILITIES.SECTION_LEAD_WARMING_DESC')"
      :show-border="false"
    >
      <div class="flex flex-col gap-4">
        <label class="flex items-center gap-3 cursor-pointer">
          <input
            v-model="leadWarming.enabled"
            type="checkbox"
            class="accent-n-brand w-4 h-4"
          />
          <span class="text-sm text-n-slate-12">
            {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.LEAD_WARMING_ENABLED') }}
          </span>
        </label>

        <template v-if="leadWarming.enabled">
          <div class="flex items-center gap-3">
            <span class="text-sm text-n-slate-11">
              {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.LEAD_WARMING_TURNS_LABEL') }}:
            </span>
            <input
              v-model.number="leadWarming.auto_suggest_after_turns"
              type="number"
              min="1"
              max="20"
              class="w-16 px-2 py-1 text-sm rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand text-center"
            />
          </div>
          <div class="flex flex-col gap-2">
            <label class="text-sm text-n-slate-11">
              {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.LEAD_WARMING_PHRASES_LABEL') }}
            </label>
            <textarea
              v-model="closingPhrasesText"
              rows="4"
              class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand resize-none"
            />
          </div>
        </template>
      </div>
    </SettingsSection>

    <SettingsSection
      :title="$t('AGENT_BOTS.CONFIG.CAPABILITIES.SECTION_REENGAGEMENT')"
      :sub-title="$t('AGENT_BOTS.CONFIG.CAPABILITIES.SECTION_REENGAGEMENT_DESC')"
      :show-border="false"
    >
      <div class="flex flex-col gap-4">
        <!-- Enable toggle -->
        <label class="flex items-center gap-3 cursor-pointer">
          <input
            v-model="reengagement.enabled"
            type="checkbox"
            class="accent-n-brand w-4 h-4"
          />
          <span class="text-sm text-n-slate-12">
            {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.REENGAGEMENT_ENABLED') }}
          </span>
        </label>

        <template v-if="reengagement.enabled">
          <!-- Attempts list -->
          <div class="flex flex-col gap-2">
            <span class="text-sm font-medium text-n-slate-12">
              {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.REENGAGEMENT_ATTEMPTS_LABEL') }}
            </span>
            <div class="flex flex-col gap-2 border border-n-weak rounded-xl p-4">
              <div
                v-for="(attempt, idx) in reengagement.attempts"
                :key="idx"
                class="flex items-center gap-2"
              >
                <span class="text-xs text-n-slate-10 w-16 shrink-0">
                  {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.REENGAGEMENT_ATTEMPT_N', { n: idx + 1 }) }}
                </span>
                <input
                  v-model.number="attempt.delay_value"
                  type="number"
                  min="1"
                  class="w-16 px-2 py-1 text-sm rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand text-center"
                />
                <select
                  v-model="attempt.delay_unit"
                  class="px-2 py-1 text-sm rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
                >
                  <option v-for="unit in DELAY_UNITS" :key="unit" :value="unit">
                    {{ $t(`AGENT_BOTS.CONFIG.CAPABILITIES.REENGAGEMENT_UNIT_${unit.toUpperCase()}`) }}
                  </option>
                </select>
                <button
                  type="button"
                  class="text-n-slate-9 hover:text-ruby-800 shrink-0 ml-auto"
                  @click="removeAttempt(idx)"
                >
                  <span class="i-lucide-trash-2 w-4 h-4" />
                </button>
              </div>

              <button
                v-if="reengagement.attempts.length < 5"
                type="button"
                class="text-sm text-n-brand hover:underline text-left mt-1"
                @click="addAttempt"
              >
                {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.REENGAGEMENT_ADD_ATTEMPT') }}
              </button>
            </div>
            <p class="text-xs text-n-slate-11">
              {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.REENGAGEMENT_ATTEMPTS_HINT') }}
            </p>
          </div>

          <!-- Stop conditions -->
          <div class="flex flex-col gap-2">
            <span class="text-sm font-medium text-n-slate-12">
              {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.REENGAGEMENT_STOP_LABEL') }}
            </span>
            <div class="flex flex-col gap-2 border border-n-weak rounded-xl p-4">
              <label
                v-for="cond in ['on_any_reply', 'on_resolved', 'on_agent_assigned']"
                :key="cond"
                class="flex items-center gap-3 cursor-pointer"
              >
                <input
                  v-model="reengagement.stop_conditions[cond]"
                  type="checkbox"
                  class="accent-n-brand w-4 h-4"
                />
                <span class="text-sm text-n-slate-12">
                  {{ $t(`AGENT_BOTS.CONFIG.CAPABILITIES.REENGAGEMENT_STOP_${cond.toUpperCase()}`) }}
                </span>
              </label>
            </div>
          </div>

          <!-- Stop keywords -->
          <div class="flex flex-col gap-2">
            <span class="text-sm font-medium text-n-slate-12">
              {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.REENGAGEMENT_KEYWORDS_LABEL') }}
            </span>
            <p class="text-xs text-n-slate-11">
              {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.REENGAGEMENT_KEYWORDS_HINT') }}
            </p>
            <div class="flex flex-col gap-2 border border-n-weak rounded-xl p-4">
              <div
                v-for="(phrase, idx) in reengagement.stop_keywords.phrases"
                :key="idx"
                class="flex items-center gap-2"
              >
                <input
                  type="text"
                  :value="phrase"
                  class="flex-1 px-3 py-1.5 text-sm rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
                  :placeholder="$t('AGENT_BOTS.CONFIG.CAPABILITIES.REENGAGEMENT_KEYWORD_PLACEHOLDER')"
                  @input="e => (reengagement.stop_keywords.phrases[idx] = e.target.value)"
                />
                <button
                  type="button"
                  class="text-n-slate-9 hover:text-ruby-800 shrink-0"
                  @click="removeKeyword(idx)"
                >
                  <span class="i-lucide-x w-4 h-4" />
                </button>
              </div>
              <div class="flex items-center justify-between mt-1">
                <button
                  type="button"
                  class="text-sm text-n-brand hover:underline text-left"
                  @click="addKeyword"
                >
                  {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.REENGAGEMENT_ADD_KEYWORD') }}
                </button>
                <label class="flex items-center gap-2 text-xs text-n-slate-11 cursor-pointer">
                  <input
                    v-model="reengagement.stop_keywords.case_insensitive"
                    type="checkbox"
                    class="accent-n-brand"
                  />
                  {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.REENGAGEMENT_CASE_INSENSITIVE') }}
                </label>
              </div>
            </div>
          </div>

          <!-- Reactivation -->
          <div class="flex flex-col gap-2">
            <span class="text-sm font-medium text-n-slate-12">
              {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.REENGAGEMENT_REACTIVATION_LABEL') }}
            </span>
            <div class="flex flex-col gap-2 border border-n-weak rounded-xl p-4">
              <label class="flex items-center gap-3 cursor-pointer">
                <input
                  v-model="reengagement.reactivation.on_bot_reply"
                  type="checkbox"
                  class="accent-n-brand w-4 h-4"
                />
                <span class="text-sm text-n-slate-12">
                  {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.REENGAGEMENT_REACTIVATION_ON_BOT_REPLY') }}
                </span>
              </label>
              <div v-if="reengagement.reactivation.on_bot_reply" class="ml-7 flex flex-col gap-1.5">
                <span class="text-xs text-n-slate-11">
                  {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.REENGAGEMENT_REACTIVATION_EXCLUDE_LABEL') }}
                </span>
                <label
                  v-for="key in ['keyword', 'api_cancel']"
                  :key="key"
                  class="flex items-center gap-2 text-xs text-n-slate-12 cursor-pointer"
                >
                  <input
                    type="checkbox"
                    :checked="reengagement.reactivation.exclude_if_cancelled_by.includes(key)"
                    class="accent-n-brand"
                    @change="e => {
                      const list = reengagement.reactivation.exclude_if_cancelled_by;
                      e.target.checked
                        ? list.push(key)
                        : list.splice(list.indexOf(key), 1);
                    }"
                  />
                  {{ $t(`AGENT_BOTS.CONFIG.CAPABILITIES.REENGAGEMENT_EXCLUDE_${key.toUpperCase()}`) }}
                </label>
              </div>
            </div>
          </div>

          <!-- API endpoint info -->
          <div class="rounded-xl border border-n-weak bg-n-alpha-1 p-4 flex flex-col gap-2">
            <span class="text-xs font-semibold text-n-slate-11 uppercase tracking-wide">
              {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.REENGAGEMENT_API_TITLE') }}
            </span>
            <p class="text-xs text-n-slate-11">
              {{ $t('AGENT_BOTS.CONFIG.CAPABILITIES.REENGAGEMENT_API_DESC') }}
            </p>
            <code class="text-xs font-mono text-n-slate-12 bg-n-background border border-n-weak rounded-lg px-3 py-2 break-all">
              DELETE /api/v1/agent_bot/conversations/{id}/reengagement
            </code>
          </div>
        </template>
      </div>
    </SettingsSection>
  </div>
</template>
