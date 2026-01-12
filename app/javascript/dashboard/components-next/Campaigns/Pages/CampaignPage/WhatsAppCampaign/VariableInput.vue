<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Input from 'dashboard/components-next/input/Input.vue';
import {
  CHATWOOT_VARIABLES,
  VARIABLE_CATEGORIES,
  isChatwootVariable,
  findVariableByKey,
  extractVariableKey,
} from 'dashboard/components-next/whatsapp/chatwootVariables';

/**
 * Check if a string contains a variable-like pattern that is NOT a valid Chatwoot variable.
 * Returns the invalid variable pattern if found, null otherwise.
 */
function findInvalidVariable(value) {
  if (!value) return null;

  // Match any {{something}} pattern
  const variablePattern = /\{\{([^}]+)\}\}/g;
  let match = variablePattern.exec(value);

  while (match) {
    const fullMatch = match[0]; // e.g., "{{matias}}"
    const innerKey = match[1].trim(); // e.g., "matias"

    // Check if it's a valid Chatwoot variable
    const isValid = CHATWOOT_VARIABLES.some(v => v.key === innerKey);

    if (!isValid) {
      return fullMatch;
    }

    match = variablePattern.exec(value);
  }

  return null;
}

const props = defineProps({
  modelValue: {
    type: String,
    default: '',
  },
  placeholder: {
    type: String,
    default: '',
  },
  disabled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:modelValue']);

const { locale, t } = useI18n();
const showVariablePicker = ref(false);
const inputRef = ref(null);
const invalidVariableWarning = ref(null);

const isUsingVariable = computed(() => isChatwootVariable(props.modelValue));

// Check for invalid variables when the value changes
watch(
  () => props.modelValue,
  newValue => {
    const invalid = findInvalidVariable(newValue);
    if (invalid) {
      invalidVariableWarning.value = t(
        'CAMPAIGN.WHATSAPP.CREATE_DIALOG.VARIABLE_PICKER.INVALID_VARIABLE',
        { variable: invalid }
      );
    } else {
      invalidVariableWarning.value = null;
    }
  },
  { immediate: true }
);

const selectedVariable = computed(() => {
  if (!isUsingVariable.value) return null;
  const key = extractVariableKey(props.modelValue);
  return key ? findVariableByKey(key) : null;
});

const displayValue = computed(() => {
  if (isUsingVariable.value && selectedVariable.value) {
    return locale.value === 'pt_BR'
      ? selectedVariable.value.labelPtBr
      : selectedVariable.value.labelEn;
  }
  return props.modelValue;
});

const getLabel = variable => {
  return locale.value === 'pt_BR' ? variable.labelPtBr : variable.labelEn;
};

const getDescription = variable => {
  return locale.value === 'pt_BR'
    ? variable.descriptionPtBr
    : variable.descriptionEn;
};

const getCategoryLabel = categoryKey => {
  const category = VARIABLE_CATEGORIES.find(c => c.key === categoryKey);
  if (!category) return categoryKey;
  return locale.value === 'pt_BR' ? category.labelPtBr : category.labelEn;
};

const groupedVariables = computed(() => {
  const groups = {};
  CHATWOOT_VARIABLES.forEach(variable => {
    if (!groups[variable.category]) {
      groups[variable.category] = [];
    }
    groups[variable.category].push(variable);
  });
  return groups;
});

const handleInputChange = value => {
  emit('update:modelValue', value);
};

const selectVariable = variable => {
  emit('update:modelValue', variable.liquidSyntax);
  showVariablePicker.value = false;
};

const clearVariable = () => {
  emit('update:modelValue', '');
  showVariablePicker.value = false;
};

const togglePicker = () => {
  showVariablePicker.value = !showVariablePicker.value;
};

const closePicker = () => {
  showVariablePicker.value = false;
};
</script>

<template>
  <div class="relative">
    <!-- Input row with variable badge/text input and picker button -->
    <div class="flex items-center gap-2">
      <div class="flex-1 min-w-0 relative">
        <!-- Show badge if using a Chatwoot variable -->
        <div
          v-if="isUsingVariable && selectedVariable"
          class="flex items-center gap-2 h-10 px-3 rounded-lg border border-woot-500 bg-woot-500/10"
        >
          <i class="i-lucide-variable text-woot-500 flex-shrink-0" />
          <span class="flex-1 min-w-0 truncate text-sm text-woot-500 font-medium">
            {{ displayValue }}
          </span>
          <button
            type="button"
            class="flex-shrink-0 p-1 rounded hover:bg-woot-500/20 text-woot-500"
            :title="$t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.VARIABLE_PICKER.CLEAR')"
            @click="clearVariable"
          >
            <i class="i-lucide-x text-sm" />
          </button>
        </div>

        <!-- Regular text input (without message - we show it separately below) -->
        <Input
          v-else
          ref="inputRef"
          :model-value="modelValue"
          :placeholder="placeholder"
          :disabled="disabled"
          @update:model-value="handleInputChange"
        />
      </div>

      <!-- Variable picker button - aligned to top -->
      <button
        type="button"
        class="flex-shrink-0 px-3 h-10 rounded-lg border transition-colors"
        :class="
          showVariablePicker
            ? 'border-woot-500 bg-woot-500/10 text-woot-500'
            : 'border-n-weak bg-n-alpha-2 text-n-slate-11 hover:border-n-slate-6 hover:bg-n-alpha-3'
        "
        :title="$t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.VARIABLE_PICKER.TITLE')"
        @click="togglePicker"
      >
        <i class="i-lucide-variable" />
      </button>
    </div>

    <!-- Warning message displayed below the full row -->
    <p
      v-if="invalidVariableWarning"
      class="mt-1 text-xs text-yellow-600 dark:text-yellow-400"
    >
      {{ invalidVariableWarning }}
    </p>

    <!-- Variable picker dropdown -->
    <div
      v-if="showVariablePicker"
      class="absolute z-50 top-full left-0 mt-1 bg-n-solid-2 border border-n-weak rounded-xl shadow-lg overflow-hidden w-[400px]"
    >
      <div class="p-3 border-b border-n-weak">
        <h4 class="text-sm font-medium text-n-slate-12">
          {{ $t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.VARIABLE_PICKER.TITLE') }}
        </h4>
        <p class="text-xs text-n-slate-11 mt-1">
          {{ $t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.VARIABLE_PICKER.DESCRIPTION') }}
        </p>
      </div>

      <div class="max-h-64 overflow-y-auto p-2">
        <div
          v-for="(variables, category) in groupedVariables"
          :key="category"
          class="mb-3 last:mb-0"
        >
          <p class="px-2 py-1 text-xs font-semibold text-n-slate-11 uppercase">
            {{ getCategoryLabel(category) }}
          </p>
          <button
            v-for="variable in variables"
            :key="variable.key"
            type="button"
            class="w-full flex items-start gap-3 px-2 py-2 rounded-lg text-left hover:bg-n-alpha-3 transition-colors"
            @click="selectVariable(variable)"
          >
            <div
              class="flex-shrink-0 w-8 h-8 rounded-lg bg-woot-500/10 flex items-center justify-center"
            >
              <i class="i-lucide-variable text-woot-500 text-sm" />
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-n-slate-12">
                {{ getLabel(variable) }}
              </p>
              <p class="text-xs text-n-slate-11">
                {{ getDescription(variable) }}
              </p>
              <code
                class="text-[10px] text-n-slate-10 font-mono bg-n-alpha-2 px-1 rounded"
              >
                {{ variable.liquidSyntax }}
              </code>
            </div>
          </button>
        </div>
      </div>

      <div class="p-2 border-t border-n-weak bg-n-alpha-1">
        <button
          type="button"
          class="w-full px-3 py-2 text-sm text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2 rounded-lg transition-colors text-center"
          @click="closePicker"
        >
          {{ $t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.VARIABLE_PICKER.CLOSE') }}
        </button>
      </div>
    </div>

    <!-- Backdrop to close picker -->
    <div
      v-if="showVariablePicker"
      class="fixed inset-0 z-40"
      @click="closePicker"
    />
  </div>
</template>

