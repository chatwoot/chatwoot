<script setup>
import { computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import { parseTemplateVariables } from 'dashboard/helper/templateHelper';

const props = defineProps({
  modelValue: {
    type: Object,
    default: () => ({ text: '', examples: [], error: '' }),
  },
  inputType: {
    type: String,
    default: 'input',
    validator: value => ['input', 'textarea'].includes(value),
  },
  maxLength: {
    type: Number,
    default: 1000,
  },
  placeholder: {
    type: String,
    default: '',
  },
  parameterType: {
    type: String,
    required: true,
  },
  maxVariables: {
    type: Number,
    default: Infinity,
  },
  label: {
    type: String,
    default: '',
  },
  helpText: {
    type: String,
    default: '',
  },
  showCharacterCount: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();

const hasVariables = computed(() => {
  return props.modelValue.examples.length > 0;
});

const hasErrors = computed(() => {
  return props.modelValue.error.length > 0;
});

const getErrorMessage = (errorKey, data = {}) => {
  if (errorKey === 'NAMED_IN_POSITIONAL') {
    return t('SETTINGS.TEMPLATES.BUILDER.VARIABLES.ERRORS.NAMED_IN_POSITIONAL');
  }
  if (errorKey === 'POSITIONAL_IN_NAMED') {
    return t('SETTINGS.TEMPLATES.BUILDER.VARIABLES.ERRORS.POSITIONAL_IN_NAMED');
  }
  if (errorKey === 'DUPLICATE_VARIABLES') {
    return t('SETTINGS.TEMPLATES.BUILDER.VARIABLES.ERRORS.DUPLICATE_VARIABLES');
  }
  if (errorKey === 'MAX_VARIABLES_EXCEEDED') {
    return t(
      'SETTINGS.TEMPLATES.BUILDER.VARIABLES.ERRORS.MAX_VARIABLES_EXCEEDED',
      data
    );
  }
  return '';
};

const updateText = value => {
  const result = parseTemplateVariables(
    value,
    props.parameterType,
    props.maxVariables,
    props.modelValue.examples
  );

  emit('update:modelValue', {
    text: result.processedText,
    examples: result.examples,
    error: getErrorMessage(result.error.key, result.error.data),
  });
};

const updateNumberExample = (index, value) => {
  const newExamples = [...(props.modelValue.examples || [])];
  newExamples[index] = value;

  emit('update:modelValue', {
    text: props.modelValue.text,
    examples: newExamples,
    error: props.modelValue.error,
  });
};

const updateNamedExample = (variableName, example) => {
  const newExamples = (props.modelValue.examples || []).map(ex =>
    ex && ex.param_name === variableName ? { ...ex, example } : ex
  );

  emit('update:modelValue', {
    text: props.modelValue.text,
    examples: newExamples,
    error: props.modelValue.error,
  });
};

const formatPositionalVariable = index => {
  return `{{${props.maxVariables === 1 ? 1 : index + 1}}}`;
};

const formatNamedVariable = name => {
  return `{{${name}}}`;
};

const getPositionalHelpText = () => {
  return t('SETTINGS.TEMPLATES.BUILDER.VARIABLES.POSITIONAL_HELP', {
    example1: '{{1}}',
    example2: '{{2}}',
  });
};

const getNamedHelpText = () => {
  return t('SETTINGS.TEMPLATES.BUILDER.VARIABLES.NAMED_HELP', {
    example_param: '{{parameter_name}}',
  });
};

const variableHelpText = computed(() => {
  return props.parameterType === 'positional'
    ? getPositionalHelpText()
    : getNamedHelpText();
});

watch(
  () => props.parameterType,
  () => {
    updateText(props.modelValue.text);
  }
);
</script>

<template>
  <div class="space-y-4">
    <!-- Input/Textarea Section -->
    <div>
      <label
        v-if="label"
        class="block text-sm font-medium text-n-slate-12 mb-2"
      >
        {{ label }}
      </label>

      <Input
        v-if="inputType === 'input'"
        :model-value="modelValue.text"
        :placeholder="placeholder"
        :message-type="hasErrors ? 'error' : 'info'"
        :show-character-count="showCharacterCount"
        :max-length="maxLength"
        @update:model-value="updateText"
      />

      <TextArea
        v-else
        :model-value="modelValue.text"
        :placeholder="placeholder"
        :max-length="maxLength"
        :message-type="hasErrors ? 'error' : 'info'"
        :show-character-count="showCharacterCount"
        @update:model-value="updateText"
      />

      <div v-if="helpText" class="mt-1">
        <span class="text-xs text-n-slate-11">
          {{ helpText }}
        </span>
      </div>

      <!-- Error Message Section -->
      <div v-if="hasErrors" class="mt-2">
        <div
          class="flex items-center gap-2 text-sm text-red-600 bg-red-50 px-3 py-2 rounded-lg"
        >
          <span class="i-lucide-alert-triangle size-4" />
          {{ modelValue.error }}
        </div>
      </div>
    </div>

    <!-- Variables Section -->
    <div v-if="hasVariables" class="space-y-3">
      <h5 class="text-sm font-medium text-n-slate-12 flex items-center gap-2">
        <span class="i-lucide-hash size-4" />
        {{ t('SETTINGS.TEMPLATES.BUILDER.VARIABLES.TITLE') }}
      </h5>

      <div class="space-y-2">
        <!-- Dynamic Help Text -->
        <p class="text-xs text-n-slate-11">
          {{ variableHelpText }}
        </p>

        <!-- Positional Parameters -->
        <div v-if="parameterType === 'positional'" class="space-y-2">
          <div
            v-for="(example, index) in modelValue.examples"
            :key="`num-${index}`"
            class="flex items-center gap-3"
          >
            <span
              class="text-sm text-n-slate-11 min-w-[60px] flex items-center justify-center"
            >
              {{ formatPositionalVariable(index) }}
            </span>
            <Input
              :model-value="example"
              :placeholder="
                t('SETTINGS.TEMPLATES.BUILDER.VARIABLES.EXAMPLE_PLACEHOLDER', {
                  index: index + 1,
                })
              "
              custom-input-class="flex-1 text-sm"
              @update:model-value="updateNumberExample(index, $event)"
            />
          </div>
        </div>

        <!-- Named Parameters -->
        <div v-if="parameterType === 'named'" class="space-y-2">
          <div
            v-for="example in modelValue.examples"
            :key="`named-${example.param_name}`"
            class="flex items-center gap-3"
          >
            <span
              class="text-sm text-n-slate-11 min-w-[60px] flex items-center justify-center"
            >
              {{ formatNamedVariable(example.param_name) }}
            </span>

            <!-- Example Value Input -->
            <Input
              :model-value="example.example"
              :placeholder="
                t(
                  'SETTINGS.TEMPLATES.BUILDER.VARIABLES.NAMED_EXAMPLE_PLACEHOLDER',
                  { name: example.param_name }
                )
              "
              custom-input-class="flex-1 text-sm"
              @update:model-value="
                updateNamedExample(example.param_name, $event)
              "
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
