<script setup>
import { useI18n } from 'vue-i18n';

import SettingsSection from 'dashboard/components/SettingsSection.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

const props = defineProps({
  form: { type: Object, required: true },
});

const { t } = useI18n();

const PRESETS = {
  vektor: {
    name: 'Vektor',
    title: 'Tu asesor de ventas',
    personality: 'Profesional, directo, analítico',
    tone: 'Formal, preciso, orientado a datos',
    goal: 'Proporcionar información exacta y facilitar decisiones informadas',
    speaking_style: 'Según el análisis de tus necesidades, el modelo X ofrece...',
    inspiration: 'Spock + consultor de McKinsey',
  },
  lala: {
    name: 'Lala',
    title: 'Tu asesora de ventas',
    personality: 'Amable, empática, súper resolutiva',
    tone: 'Cercano, cálido, positivo sin ser exagerado',
    goal: 'Acompañar y facilitar la decisión de compra del cliente',
    speaking_style:
      '¡Claro que sí! Para una familia de 4, te recomendaría el Corolla Cross. ¿Tienes niños pequeños?',
    inspiration: 'Michelle Obama + Alegría de Intensamente',
  },
  sol: {
    name: 'Sol',
    title: 'Tu asesor de confianza',
    personality: 'Energético, optimista, motivador',
    tone: 'Dinámico, entusiasta, inspirador',
    goal: 'Inspirar al cliente a tomar acción y encontrar su opción ideal',
    speaking_style:
      '¡Esto es justo lo que buscabas! Mira qué increíble opción tenemos para ti.',
    inspiration: 'Coach de vida + presentador de TV',
  },
  nova: {
    name: 'Nova',
    title: 'Tu asesora virtual',
    personality: 'Neutral, eficiente, moderna',
    tone: 'Conversacional, ágil, sin jergas',
    goal: 'Resolver consultas rápido y con precisión',
    speaking_style:
      'Entendido. Para ese perfil te recomiendo el modelo A o el B. ¿Cuál te interesa?',
    inspiration: 'Asistente de IA moderna + ChatGPT',
  },
};

const applyPreset = key => {
  const preset = PRESETS[key];
  if (!preset) return;
  props.form.assistant_config.preset = key;
  Object.assign(props.form.assistant_config, preset);
};

const presetOptions = [
  { value: '', label: t('AGENT_BOTS.CONFIG.ASSISTANT.PRESET_PLACEHOLDER') },
  ...Object.entries(PRESETS).map(([key]) => ({
    value: key,
    label: t(`AGENT_BOTS.CONFIG.ASSISTANT.PRESETS.${key}`),
  })),
  {
    value: 'custom',
    label: t('AGENT_BOTS.CONFIG.ASSISTANT.PRESETS.custom'),
  },
];
</script>

<template>
  <div>
    <SettingsSection
      :title="$t('AGENT_BOTS.CONFIG.ASSISTANT.SECTION_PRESET')"
      :sub-title="$t('AGENT_BOTS.CONFIG.ASSISTANT.SECTION_PRESET_DESC')"
    >
      <div class="flex flex-col gap-2">
        <label class="text-sm font-medium text-n-slate-12">
          {{ $t('AGENT_BOTS.CONFIG.ASSISTANT.PRESET_LABEL') }}
        </label>
        <select
          :value="form.assistant_config.preset"
          class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
          @change="e => applyPreset(e.target.value)"
        >
          <option
            v-for="opt in presetOptions"
            :key="opt.value"
            :value="opt.value"
          >
            {{ opt.label }}
          </option>
        </select>
        <p class="text-xs text-n-slate-11">
          {{ $t('AGENT_BOTS.CONFIG.ASSISTANT.PRESET_HINT') }}
        </p>
      </div>
    </SettingsSection>

    <SettingsSection
      :title="$t('AGENT_BOTS.CONFIG.ASSISTANT.SECTION_IDENTITY')"
      :sub-title="$t('AGENT_BOTS.CONFIG.ASSISTANT.SECTION_IDENTITY_DESC')"
    >
      <div class="grid grid-cols-2 gap-4">
        <Input
          v-model="form.assistant_config.name"
          :label="$t('AGENT_BOTS.CONFIG.ASSISTANT.NAME_LABEL')"
          :placeholder="$t('AGENT_BOTS.CONFIG.ASSISTANT.NAME_PLACEHOLDER')"
        />
        <Input
          v-model="form.assistant_config.title"
          :label="$t('AGENT_BOTS.CONFIG.ASSISTANT.TITLE_LABEL')"
          :placeholder="$t('AGENT_BOTS.CONFIG.ASSISTANT.TITLE_PLACEHOLDER')"
        />
      </div>
    </SettingsSection>

    <SettingsSection
      :title="$t('AGENT_BOTS.CONFIG.ASSISTANT.SECTION_CHARACTER')"
      :sub-title="$t('AGENT_BOTS.CONFIG.ASSISTANT.SECTION_CHARACTER_DESC')"
    >
      <div class="flex flex-col gap-4">
        <Input
          v-model="form.assistant_config.personality"
          :label="$t('AGENT_BOTS.CONFIG.ASSISTANT.PERSONALITY_LABEL')"
          :placeholder="$t('AGENT_BOTS.CONFIG.ASSISTANT.PERSONALITY_PLACEHOLDER')"
        />
        <Input
          v-model="form.assistant_config.tone"
          :label="$t('AGENT_BOTS.CONFIG.ASSISTANT.TONE_LABEL')"
          :placeholder="$t('AGENT_BOTS.CONFIG.ASSISTANT.TONE_PLACEHOLDER')"
        />
        <Input
          v-model="form.assistant_config.goal"
          :label="$t('AGENT_BOTS.CONFIG.ASSISTANT.GOAL_LABEL')"
          :placeholder="$t('AGENT_BOTS.CONFIG.ASSISTANT.GOAL_PLACEHOLDER')"
        />
      </div>
    </SettingsSection>

    <SettingsSection
      :title="$t('AGENT_BOTS.CONFIG.ASSISTANT.SECTION_STYLE')"
      :sub-title="$t('AGENT_BOTS.CONFIG.ASSISTANT.SECTION_STYLE_DESC')"
      :show-border="false"
    >
      <div class="flex flex-col gap-4">
        <TextArea
          v-model="form.assistant_config.speaking_style"
          :label="$t('AGENT_BOTS.CONFIG.ASSISTANT.SPEAKING_STYLE_LABEL')"
          :placeholder="
            $t('AGENT_BOTS.CONFIG.ASSISTANT.SPEAKING_STYLE_PLACEHOLDER')
          "
          :rows="3"
        />
        <div class="flex flex-col gap-1">
          <TextArea
            v-model="form.assistant_config.inspiration"
            :label="$t('AGENT_BOTS.CONFIG.ASSISTANT.INSPIRATION_LABEL')"
            :placeholder="
              $t('AGENT_BOTS.CONFIG.ASSISTANT.INSPIRATION_PLACEHOLDER')
            "
            :rows="2"
          />
          <p class="text-xs text-n-slate-11">
            {{ $t('AGENT_BOTS.CONFIG.ASSISTANT.INSPIRATION_HINT') }}
          </p>
        </div>
      </div>
    </SettingsSection>
  </div>
</template>
