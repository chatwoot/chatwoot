<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

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

const name = ref('');
const category = ref('UTILITY');
const language = ref('pt_BR');
const headerText = ref('');
const bodyText = ref('');
const footerText = ref('');
const buttons = ref([]);
const isSubmitting = ref(false);
const errors = ref({});

const bodyCharsRemaining = computed(() => BODY_MAX - bodyText.value.length);
const headerCharsRemaining = computed(() => HEADER_MAX - headerText.value.length);
const footerCharsRemaining = computed(() => FOOTER_MAX - footerText.value.length);

const canAddButton = computed(() => buttons.value.length < MAX_BUTTONS);

const previewVariables = text => {
  return text.replace(
    /\{\{([a-zA-Z_][a-zA-Z0-9_]*)\}\}/g,
    '<span class="px-1 rounded bg-n-amber-3 text-n-amber-11 text-xs font-mono">{{$1}}</span>'
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

const handleSubmit = async () => {
  if (!validate()) return;

  isSubmitting.value = true;
  try {
    const template = {
      name: name.value.trim(),
      category: category.value,
      language: language.value,
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
  <div class="flex gap-4 w-full min-h-0">
    <!-- Form Column -->
    <div class="flex-1 overflow-y-auto pr-2 space-y-4">
      <!-- Template Name -->
      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-1">
          {{ t('WHATSAPP_TEMPLATES.CREATOR.NAME_LABEL') }}
        </label>
        <input
          v-model="name"
          type="text"
          :placeholder="t('WHATSAPP_TEMPLATES.CREATOR.NAME_PLACEHOLDER')"
          class="reset-base w-full h-9 px-2.5 rounded-lg bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand"
          autocomplete="off"
          @input="enforceSnakeCase"
        />
        <p class="mt-0.5 text-xs text-n-slate-10">
          {{ t('WHATSAPP_TEMPLATES.CREATOR.NAME_HINT') }}
        </p>
        <p v-if="errors.name" class="mt-0.5 text-xs text-n-ruby-11">
          {{ errors.name }}
        </p>
      </div>

      <!-- Category + Language row -->
      <div class="flex gap-3">
        <div class="flex-1">
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{ t('WHATSAPP_TEMPLATES.CREATOR.CATEGORY_LABEL') }}
          </label>
          <select
            v-model="category"
            class="reset-base w-full h-9 px-2.5 rounded-lg bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand"
          >
            <option value="UTILITY">
              {{ t('WHATSAPP_TEMPLATES.CREATOR.CATEGORIES.UTILITY') }}
            </option>
            <option value="MARKETING">
              {{ t('WHATSAPP_TEMPLATES.CREATOR.CATEGORIES.MARKETING') }}
            </option>
          </select>
        </div>
        <div class="flex-1">
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{ t('WHATSAPP_TEMPLATES.CREATOR.LANGUAGE_LABEL') }}
          </label>
          <input
            v-model="language"
            type="text"
            class="reset-base w-full h-9 px-2.5 rounded-lg bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand"
          />
        </div>
      </div>

      <!-- Header Text -->
      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-1">
          {{ t('WHATSAPP_TEMPLATES.CREATOR.HEADER_LABEL') }}
        </label>
        <input
          v-model="headerText"
          type="text"
          :placeholder="t('WHATSAPP_TEMPLATES.CREATOR.HEADER_PLACEHOLDER')"
          :maxlength="HEADER_MAX"
          class="reset-base w-full h-9 px-2.5 rounded-lg bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand"
        />
        <div class="flex justify-between mt-0.5">
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
        <label class="block text-sm font-medium text-n-slate-12 mb-1">
          {{ t('WHATSAPP_TEMPLATES.CREATOR.BODY_LABEL') }}
        </label>
        <textarea
          v-model="bodyText"
          rows="5"
          :placeholder="t('WHATSAPP_TEMPLATES.CREATOR.BODY_PLACEHOLDER')"
          :maxlength="BODY_MAX"
          class="reset-base w-full px-2.5 py-2 rounded-lg bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand resize-none"
        />
        <div class="flex justify-between mt-0.5">
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
      </div>

      <!-- Footer Text -->
      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-1">
          {{ t('WHATSAPP_TEMPLATES.CREATOR.FOOTER_LABEL') }}
        </label>
        <input
          v-model="footerText"
          type="text"
          :placeholder="t('WHATSAPP_TEMPLATES.CREATOR.FOOTER_PLACEHOLDER')"
          :maxlength="FOOTER_MAX"
          class="reset-base w-full h-9 px-2.5 rounded-lg bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand"
        />
        <div class="flex justify-between mt-0.5">
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
        <label class="block text-sm font-medium text-n-slate-12 mb-1">
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
              class="reset-base flex-1 h-9 px-2.5 rounded-lg bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand"
            />
            <button
              class="flex items-center justify-center w-9 h-9 rounded-lg hover:bg-n-alpha-2 dark:hover:bg-n-solid-2 text-n-slate-10 hover:text-n-ruby-11"
              :aria-label="t('WHATSAPP_TEMPLATES.CREATOR.REMOVE_BUTTON')"
              @click="removeButton(idx)"
            >
              <Icon icon="i-lucide-x" class="size-4" />
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
          class="mt-2 flex items-center gap-1.5 text-sm text-n-brand hover:text-n-brand-dark"
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
      <footer class="flex gap-2 justify-end pt-2 pb-1">
        <NextButton
          faded
          slate
          :label="t('WHATSAPP_TEMPLATES.CREATOR.BACK')"
          @click="$emit('back')"
        />
        <NextButton
          :label="
            isSubmitting
              ? t('WHATSAPP_TEMPLATES.CREATOR.SUBMITTING')
              : t('WHATSAPP_TEMPLATES.CREATOR.SUBMIT')
          "
          :disabled="isSubmitting"
          @click="handleSubmit"
        />
      </footer>
    </div>

    <!-- Preview Column -->
    <div class="w-72 shrink-0 overflow-y-auto">
      <p class="text-sm font-medium text-n-slate-12 mb-2">
        {{ t('WHATSAPP_TEMPLATES.CREATOR.PREVIEW_TITLE') }}
      </p>
      <div
        class="rounded-xl bg-n-alpha-black2 p-4 space-y-2 outline outline-1 outline-n-weak"
      >
        <!-- WhatsApp-style bubble -->
        <div class="rounded-lg bg-white dark:bg-n-solid-3 p-3 shadow-sm">
          <!-- Header -->
          <p
            v-if="headerText"
            class="font-semibold text-sm text-n-slate-12 mb-1"
            v-html="headerPreview"
          />
          <!-- Body -->
          <p
            v-if="bodyText"
            class="text-sm text-n-slate-12 whitespace-pre-wrap"
            v-html="bodyPreview"
          />
          <p v-else class="text-sm text-n-slate-10 italic">
            {{ t('WHATSAPP_TEMPLATES.CREATOR.BODY_PLACEHOLDER') }}
          </p>
          <!-- Footer -->
          <p
            v-if="footerText"
            class="text-xs text-n-slate-10 mt-2"
          >
            {{ footerText }}
          </p>
        </div>
        <!-- Buttons -->
        <div
          v-for="(btn, idx) in buttons"
          :key="idx"
          class="text-center py-1.5 rounded-lg bg-white dark:bg-n-solid-3 text-sm text-n-blue-11 shadow-sm"
        >
          {{ btn.text || `Button ${idx + 1}` }}
        </div>
      </div>
      <!-- Meta info -->
      <div class="mt-3 space-y-1">
        <p v-if="name" class="text-xs text-n-slate-10">
          <span class="font-medium">Name:</span> {{ name }}
        </p>
        <p class="text-xs text-n-slate-10">
          <span class="font-medium">Category:</span> {{ category }}
        </p>
        <p class="text-xs text-n-slate-10">
          <span class="font-medium">Language:</span> {{ language }}
        </p>
      </div>
    </div>
  </div>
</template>
