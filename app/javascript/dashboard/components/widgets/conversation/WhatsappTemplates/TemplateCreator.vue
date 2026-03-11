<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  inboxId: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['templateCreated', 'back']);

const { t } = useI18n();
const store = useStore();

const NAME_PATTERN = /^[a-z][a-z0-9_]*$/;
const BODY_MAX = 1024;
const HEADER_MAX = 60;
const FOOTER_MAX = 60;
const BUTTON_TEXT_MAX = 25;
const MAX_BUTTONS = 10;

const wrapVar = key => `{{${key}}}`;

// Locked values
const LOCKED_CATEGORY = 'MARKETING';
const LOCKED_LANGUAGE = 'pt_BR';

const name = ref('');
const headerText = ref('');
const bodyText = ref('');
const footerText = ref('');
const buttons = ref([]);
const isSubmitting = ref(false);
const errors = ref({});
const showVariablePicker = ref(false);
const activeField = ref('bodyText'); // which field to insert variable into

// Available contact variables from Chatwit database
const CONTACT_VARIABLES = [
  { key: 'contact_name', label: 'Nome do contato', example: 'Maria Silva' },
  { key: 'contact_phone', label: 'Telefone', example: '+5511999887766' },
  { key: 'contact_email', label: 'E-mail', example: 'maria@email.com' },
  { key: 'company_name', label: 'Nome da empresa', example: 'Empresa ABC' },
];

const bodyCharsRemaining = computed(() => BODY_MAX - bodyText.value.length);
const headerCharsRemaining = computed(
  () => HEADER_MAX - headerText.value.length
);
const footerCharsRemaining = computed(
  () => FOOTER_MAX - footerText.value.length
);

const canAddButton = computed(() => buttons.value.length < MAX_BUTTONS);

// Extract variables present in the body for the preview
const usedVariables = computed(() => {
  const matches = bodyText.value.match(/\{\{([a-zA-Z_][a-zA-Z0-9_]*)\}\}/g);
  return matches ? [...new Set(matches)] : [];
});

// Build a map of variable key -> example value for preview
const variableExampleMap = Object.fromEntries(
  CONTACT_VARIABLES.map(v => [v.key, v.example])
);

const previewVariables = text => {
  return text.replace(
    /\{\{([a-zA-Z_][a-zA-Z0-9_]*)\}\}/g,
    (_, key) => {
      const example = variableExampleMap[key] || key;
      return `<span class="inline-block px-1 py-0.5 rounded bg-emerald-50 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300 text-xs font-medium">${example}</span>`;
    }
  );
};

const headerPreview = computed(() =>
  headerText.value ? previewVariables(headerText.value) : ''
);
const bodyPreview = computed(() =>
  bodyText.value ? previewVariables(bodyText.value) : ''
);

const validate = () => {
  const e = {};

  if (!name.value.trim()) {
    e.name = t('WHATSAPP_TEMPLATES.CREATOR.VALIDATION.NAME_REQUIRED');
  } else if (!NAME_PATTERN.test(name.value.trim())) {
    e.name = t('WHATSAPP_TEMPLATES.CREATOR.VALIDATION.NAME_FORMAT');
  }

  if (!bodyText.value.trim()) {
    e.bodyText = t('WHATSAPP_TEMPLATES.CREATOR.VALIDATION.BODY_REQUIRED');
  } else if (bodyText.value.length > BODY_MAX) {
    e.bodyText = t('WHATSAPP_TEMPLATES.CREATOR.VALIDATION.BODY_MAX');
  }

  if (headerText.value.length > HEADER_MAX) {
    e.headerText = t('WHATSAPP_TEMPLATES.CREATOR.VALIDATION.HEADER_MAX');
  }

  if (footerText.value.length > FOOTER_MAX) {
    e.footerText = t('WHATSAPP_TEMPLATES.CREATOR.VALIDATION.FOOTER_MAX');
  }

  buttons.value.forEach((btn, idx) => {
    if (!btn.text.trim()) {
      e[`button_${idx}`] = t(
        'WHATSAPP_TEMPLATES.CREATOR.VALIDATION.BUTTON_TEXT_REQUIRED'
      );
    } else if (btn.text.length > BUTTON_TEXT_MAX) {
      e[`button_${idx}`] = t(
        'WHATSAPP_TEMPLATES.CREATOR.VALIDATION.BUTTON_MAX'
      );
    }
  });

  errors.value = e;
  return Object.keys(e).length === 0;
};

const addButton = () => {
  if (canAddButton.value) {
    buttons.value.push({ type: 'QUICK_REPLY', text: '' });
  }
};

const removeButton = index => {
  buttons.value.splice(index, 1);
};

const enforceSnakeCase = () => {
  name.value = name.value
    .toLowerCase()
    .replace(/[^a-z0-9_]/g, '_')
    .replace(/^[0-9_]+/, '');
};

const insertVariable = variable => {
  const tag = `{{${variable.key}}}`;
  if (activeField.value === 'headerText') {
    headerText.value += tag;
  } else {
    bodyText.value += tag;
  }
  showVariablePicker.value = false;
};

const openVariablePicker = field => {
  activeField.value = field;
  showVariablePicker.value = !showVariablePicker.value;
};

const handleSubmit = async () => {
  if (!validate()) return;

  isSubmitting.value = true;
  try {
    const template = {
      name: name.value.trim(),
      category: LOCKED_CATEGORY,
      language: LOCKED_LANGUAGE,
      body_text: bodyText.value.trim(),
    };

    if (headerText.value.trim()) {
      template.header_text = headerText.value.trim();
    }
    if (footerText.value.trim()) {
      template.footer_text = footerText.value.trim();
    }
    if (buttons.value.length > 0) {
      template.buttons = buttons.value.map(btn => ({
        type: 'QUICK_REPLY',
        text: btn.text.trim(),
      }));
    }

    await store.dispatch('inboxes/createWhatsappTemplate', {
      inboxId: props.inboxId,
      template,
    });

    useAlert(t('WHATSAPP_TEMPLATES.CREATOR.SUCCESS'));

    // Trigger template sync so the new template appears after approval
    store.dispatch('inboxes/syncTemplates', props.inboxId);

    emit('templateCreated');
  } catch (error) {
    const msg =
      error?.response?.data?.error ||
      error?.response?.data?.errors?.[0] ||
      error.message;
    useAlert(t('WHATSAPP_TEMPLATES.CREATOR.ERROR', { error: msg }));
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <div class="w-full">
    <div class="flex gap-6">
      <!-- Form Column -->
      <div class="flex-1 space-y-5">
        <!-- Template Name -->
        <div>
          <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
            {{ t('WHATSAPP_TEMPLATES.CREATOR.NAME_LABEL') }}
          </label>
          <input
            v-model="name"
            type="text"
            :placeholder="t('WHATSAPP_TEMPLATES.CREATOR.NAME_PLACEHOLDER')"
            class="reset-base w-full h-10 px-3 rounded-xl bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand transition-all"
            autocomplete="off"
            @input="enforceSnakeCase"
          />
          <p class="mt-1 text-xs text-n-slate-10">
            {{ t('WHATSAPP_TEMPLATES.CREATOR.NAME_HINT') }}
          </p>
          <p v-if="errors.name" class="mt-1 text-xs text-n-ruby-11">
            {{ errors.name }}
          </p>
        </div>

        <!-- Category + Language (LOCKED) -->
        <div class="flex gap-3">
          <div class="flex-1">
            <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
              {{ t('WHATSAPP_TEMPLATES.CREATOR.CATEGORY_LABEL') }}
            </label>
            <div
              class="flex items-center gap-2 h-10 px-3 rounded-xl bg-n-slate-3 dark:bg-n-solid-2 text-n-slate-11 text-sm outline outline-1 outline-n-weak cursor-not-allowed"
            >
              <Icon icon="i-lucide-lock" class="size-3.5 text-n-slate-9 shrink-0" />
              <span>{{ t('WHATSAPP_TEMPLATES.CREATOR.CATEGORIES.MARKETING') }}</span>
            </div>
            <p class="mt-1 text-xs text-n-slate-10">
              {{ t('WHATSAPP_TEMPLATES.CREATOR.CATEGORY_LOCKED_HINT') }}
            </p>
          </div>
          <div class="flex-1">
            <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
              {{ t('WHATSAPP_TEMPLATES.CREATOR.LANGUAGE_LABEL') }}
            </label>
            <div
              class="flex items-center gap-2 h-10 px-3 rounded-xl bg-n-slate-3 dark:bg-n-solid-2 text-n-slate-11 text-sm outline outline-1 outline-n-weak cursor-not-allowed"
            >
              <Icon icon="i-lucide-lock" class="size-3.5 text-n-slate-9 shrink-0" />
              <span>Portugues (BR)</span>
            </div>
          </div>
        </div>

        <!-- Header Text -->
        <div>
          <div class="flex items-center justify-between mb-1.5">
            <label class="text-sm font-semibold text-n-slate-12">
              {{ t('WHATSAPP_TEMPLATES.CREATOR.HEADER_LABEL') }}
            </label>
            <button
              class="flex items-center gap-1 px-2.5 py-1 text-xs font-medium rounded-lg text-n-brand hover:bg-n-brand/10 transition-colors cursor-pointer"
              @click="openVariablePicker('headerText')"
            >
              <Icon icon="i-lucide-braces" class="size-3.5" />
              {{ t('WHATSAPP_TEMPLATES.CREATOR.INSERT_VARIABLE') }}
            </button>
          </div>
          <input
            v-model="headerText"
            type="text"
            :placeholder="t('WHATSAPP_TEMPLATES.CREATOR.HEADER_PLACEHOLDER')"
            :maxlength="HEADER_MAX"
            class="reset-base w-full h-10 px-3 rounded-xl bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand transition-all"
          />
          <div class="flex justify-between mt-1">
            <p v-if="errors.headerText" class="text-xs text-n-ruby-11">
              {{ errors.headerText }}
            </p>
            <p class="text-xs text-n-slate-10 ml-auto">
              {{
                t('WHATSAPP_TEMPLATES.CREATOR.CHARS_REMAINING', {
                  count: headerCharsRemaining,
                })
              }}
            </p>
          </div>
        </div>

        <!-- Body Text -->
        <div>
          <div class="flex items-center justify-between mb-1.5">
            <label class="text-sm font-semibold text-n-slate-12">
              {{ t('WHATSAPP_TEMPLATES.CREATOR.BODY_LABEL') }}
              <span class="text-n-ruby-11">*</span>
            </label>
            <!-- Variable picker toggle -->
            <div class="relative">
              <button
                class="flex items-center gap-1 px-2.5 py-1 text-xs font-medium rounded-lg text-n-brand hover:bg-n-brand/10 transition-colors"
                @click="openVariablePicker('bodyText')"
              >
                <Icon icon="i-lucide-braces" class="size-3.5" />
                {{ t('WHATSAPP_TEMPLATES.CREATOR.INSERT_VARIABLE') }}
              </button>

              <!-- Variable picker dropdown -->
              <div
                v-if="showVariablePicker"
                class="absolute right-0 top-full mt-1 z-50 w-72 rounded-xl bg-white dark:bg-n-solid-3 shadow-lg outline outline-1 outline-n-weak overflow-hidden"
              >
                <div class="px-3 py-2 bg-n-slate-2 dark:bg-n-solid-2">
                  <p class="text-xs font-semibold text-n-slate-11 uppercase tracking-wider">
                    {{ t('WHATSAPP_TEMPLATES.CREATOR.VARIABLES_TITLE') }}
                  </p>
                </div>
                <div class="p-1.5">
                  <button
                    v-for="variable in CONTACT_VARIABLES"
                    :key="variable.key"
                    class="flex items-center gap-3 w-full px-3 py-2 rounded-lg hover:bg-n-alpha-2 dark:hover:bg-n-solid-2 transition-colors text-left"
                    @click="insertVariable(variable)"
                  >
                    <div class="flex items-center justify-center w-8 h-8 rounded-lg bg-emerald-100 dark:bg-emerald-900/30">
                      <Icon icon="i-lucide-user" class="size-4 text-emerald-600 dark:text-emerald-400" />
                    </div>
                    <div class="flex-1 min-w-0">
                      <p class="text-sm font-medium text-n-slate-12 truncate">
                        {{ variable.label }}
                      </p>
                      <p class="text-xs text-n-slate-10 font-mono">
                        {{ wrapVar(variable.key) }}
                      </p>
                    </div>
                    <span class="text-xs text-n-slate-9 italic shrink-0">
                      {{ variable.example }}
                    </span>
                  </button>
                </div>
              </div>
            </div>
          </div>
          <textarea
            v-model="bodyText"
            rows="5"
            :placeholder="t('WHATSAPP_TEMPLATES.CREATOR.BODY_PLACEHOLDER')"
            :maxlength="BODY_MAX"
            class="reset-base w-full px-3 py-2.5 rounded-xl bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand resize-none transition-all"
          />
          <div class="flex justify-between mt-1">
            <p v-if="errors.bodyText" class="text-xs text-n-ruby-11">
              {{ errors.bodyText }}
            </p>
            <p
              class="text-xs ml-auto"
              :class="
                bodyCharsRemaining < 50
                  ? 'text-n-ruby-11'
                  : 'text-n-slate-10'
              "
            >
              {{
                t('WHATSAPP_TEMPLATES.CREATOR.CHARS_REMAINING', {
                  count: bodyCharsRemaining,
                })
              }}
            </p>
          </div>

          <!-- Used variables badges -->
          <div
            v-if="usedVariables.length"
            class="flex flex-wrap gap-1.5 mt-2"
          >
            <span
              v-for="v in usedVariables"
              :key="v"
              class="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300 text-xs font-mono"
            >
              <Icon icon="i-lucide-braces" class="size-3" />
              {{ v }}
            </span>
          </div>
        </div>

        <!-- Footer Text -->
        <div>
          <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
            {{ t('WHATSAPP_TEMPLATES.CREATOR.FOOTER_LABEL') }}
          </label>
          <input
            v-model="footerText"
            type="text"
            :placeholder="t('WHATSAPP_TEMPLATES.CREATOR.FOOTER_PLACEHOLDER')"
            :maxlength="FOOTER_MAX"
            class="reset-base w-full h-10 px-3 rounded-xl bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand transition-all"
          />
          <div class="flex justify-between mt-1">
            <p v-if="errors.footerText" class="text-xs text-n-ruby-11">
              {{ errors.footerText }}
            </p>
            <p class="text-xs text-n-slate-10 ml-auto">
              {{
                t('WHATSAPP_TEMPLATES.CREATOR.CHARS_REMAINING', {
                  count: footerCharsRemaining,
                })
              }}
            </p>
          </div>
        </div>

        <!-- Quick Reply Buttons -->
        <div>
          <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
            {{ t('WHATSAPP_TEMPLATES.CREATOR.BUTTONS_LABEL') }}
          </label>
          <div class="space-y-2">
            <div
              v-for="(btn, idx) in buttons"
              :key="idx"
              class="flex gap-2 items-center"
            >
              <input
                v-model="btn.text"
                type="text"
                :placeholder="
                  t('WHATSAPP_TEMPLATES.CREATOR.BUTTON_PLACEHOLDER')
                "
                :maxlength="BUTTON_TEXT_MAX"
                class="reset-base flex-1 h-10 px-3 rounded-xl bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand transition-all"
              />
              <button
                class="flex items-center justify-center w-10 h-10 rounded-xl hover:bg-n-alpha-2 dark:hover:bg-n-solid-2 text-n-slate-10 hover:text-n-ruby-11 transition-colors"
                :aria-label="t('WHATSAPP_TEMPLATES.CREATOR.REMOVE_BUTTON')"
                @click="removeButton(idx)"
              >
                <Icon icon="i-lucide-trash-2" class="size-4" />
              </button>
              <p
                v-if="errors[`button_${idx}`]"
                class="text-xs text-n-ruby-11 w-full"
              >
                {{ errors[`button_${idx}`] }}
              </p>
            </div>
          </div>
          <button
            v-if="canAddButton"
            class="mt-2 flex items-center gap-1.5 text-sm font-medium text-n-brand hover:text-n-brand-dark transition-colors"
            @click="addButton"
          >
            <Icon icon="i-lucide-plus" class="size-4" />
            {{ t('WHATSAPP_TEMPLATES.CREATOR.ADD_BUTTON') }}
          </button>
          <p
            v-if="!canAddButton"
            class="mt-1 text-xs text-n-slate-10"
          >
            {{ t('WHATSAPP_TEMPLATES.CREATOR.VALIDATION.MAX_BUTTONS') }}
          </p>
        </div>

        <!-- Actions -->
        <div class="flex justify-end pt-3 pb-1 border-t border-n-weak">
          <Button
            :is-loading="isSubmitting"
            :disabled="isSubmitting"
            :label="
              isSubmitting
                ? t('WHATSAPP_TEMPLATES.CREATOR.SUBMITTING')
                : t('WHATSAPP_TEMPLATES.CREATOR.SUBMIT')
            "
            icon="i-lucide-send"
            @click="handleSubmit"
          />
        </div>
      </div>

      <!-- Preview Column -->
      <div class="w-72 shrink-0 sticky top-0 self-start max-h-[calc(100vh-8rem)] overflow-y-auto">
        <p class="text-sm font-semibold text-n-slate-12 mb-3">
          {{ t('WHATSAPP_TEMPLATES.CREATOR.PREVIEW_TITLE') }}
        </p>

        <!-- WhatsApp phone mockup -->
        <div
          class="rounded-2xl p-4 space-y-2"
          style="background: linear-gradient(135deg, #e8ded3 0%, #d4cabe 100%)"
        >
          <!-- WhatsApp-style bubble -->
          <div class="rounded-xl bg-white dark:bg-n-solid-3 p-3.5 shadow-sm">
            <!-- Header -->
            <p
              v-if="headerText"
              class="font-semibold text-sm text-n-slate-12 mb-1.5"
              v-html="headerPreview"
            />
            <!-- Body -->
            <p
              v-if="bodyText"
              class="text-sm text-n-slate-12 whitespace-pre-wrap leading-relaxed"
              v-html="bodyPreview"
            />
            <p v-else class="text-sm text-n-slate-10 italic">
              {{ t('WHATSAPP_TEMPLATES.CREATOR.BODY_PLACEHOLDER') }}
            </p>
            <!-- Footer -->
            <p
              v-if="footerText"
              class="text-xs text-n-slate-10 mt-2.5 pt-1.5 border-t border-n-weak/50"
            >
              {{ footerText }}
            </p>
          </div>
          <!-- Buttons as WhatsApp-style pills -->
          <div
            v-for="(btn, idx) in buttons"
            :key="idx"
            class="text-center py-2 rounded-xl bg-white dark:bg-n-solid-3 text-sm font-medium text-[#0088cc] shadow-sm"
          >
            {{ btn.text || `${t('WHATSAPP_TEMPLATES.CREATOR.BUTTONS_LABEL')} ${idx + 1}` }}
          </div>
        </div>

        <!-- Meta info badges -->
        <div class="mt-4 space-y-2">
          <div v-if="name" class="flex items-center gap-2">
            <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-n-slate-3 dark:bg-n-solid-2 text-xs text-n-slate-11">
              <Icon icon="i-lucide-file-text" class="size-3" />
              {{ name }}
            </span>
          </div>
          <div class="flex gap-2">
            <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-n-amber-3 dark:bg-n-amber-3 text-xs text-n-amber-11 font-medium">
              <Icon icon="i-lucide-megaphone" class="size-3" />
              MARKETING
            </span>
            <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-n-blue-3 dark:bg-n-blue-3 text-xs text-n-blue-11 font-medium">
              <Icon icon="i-lucide-globe" class="size-3" />
              pt_BR
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- Click-away for variable picker -->
    <div
      v-if="showVariablePicker"
      class="fixed inset-0 z-40"
      @click="showVariablePicker = false"
    />
  </div>
</template>
