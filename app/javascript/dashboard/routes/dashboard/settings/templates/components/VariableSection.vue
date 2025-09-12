<script setup>
import { computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

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
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();

const parseNumberVariables = text => {
  const numberVariableRegex = /\{\{(\d+)\}\}/g;
  const namedVariableRegex = /\{\{([a-zA-Z][a-zA-Z0-9_]*)\}\}/g;
  const examples = [...(props.modelValue.examples || [])];

  // Check for named variables in positional mode
  if (namedVariableRegex.test(text)) {
    return {
      processedText: text,
      examples: [],
      error: 'Named variables are not allowed in positional parameter mode',
    };
  }

  let count = 0;

  const processedText = text.replace(numberVariableRegex, () => {
    count += 1;
    if (count > props.maxVariables) {
      return '';
    }
    return `{{${count}}}`;
  });

  if (props.modelValue.examples.length > count) {
    examples.splice(count);
  }

  for (let i = examples.length; i < count; i += 1) {
    examples.push('');
  }

  return { processedText, examples, error: '' };
};

/**
 * @param {string} text
 */
const parseNamedVariable = text => {
  let error = '';
  const numberVariableRegex = /\{\{(\d+)\}\}/g;
  // Should start with a char, can end with a number or underscore
  const regex = /\{\{([a-zA-Z][a-zA-Z0-9_]*)\}\}/g;

  // Check for positional variables in named mode
  if (numberVariableRegex.test(text)) {
    return {
      processedText: text,
      examples: [],
      error: 'Positional variables are not allowed in named parameter mode',
    };
  }

  const matches = [...text.matchAll(regex)];
  const variableNames = matches.map(match => match[1]);
  const uniqueNames = new Set(variableNames);

  // Check for duplicate variables (priority error)
  if (variableNames.length !== uniqueNames.size) {
    error = 'Text cannot contain duplicate variables';
  }
  // Check max variables limit (only if no duplicate error)
  else if (variableNames.length > props.maxVariables) {
    error = `Maximum ${props.maxVariables} variables allowed`;
  }

  // Create examples array based on unique variables
  const examples = Array.from(uniqueNames).map(param_name => ({
    param_name,
    example:
      props.modelValue.examples.find(ex => ex && ex.param_name === param_name)
        ?.example || '',
  }));

  return {
    processedText: text, // Named variables don't need text processing
    examples,
    error,
  };
};

const parseVariables = text => {
  if (props.parameterType === 'positional') {
    return parseNumberVariables(text);
  }
  return parseNamedVariable(text);
};

const hasVariables = computed(() => {
  return props.modelValue.examples.length > 0;
});

const hasErrors = computed(() => {
  return props.modelValue.error.length > 0;
});

const updateText = value => {
  const { processedText, examples, error } = parseVariables(value);

  emit('update:modelValue', {
    text: processedText,
    examples,
    error,
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
        show-character-count
        :max-length="maxLength"
        @update:model-value="updateText"
      />

      <TextArea
        v-else
        :model-value="modelValue.text"
        :placeholder="placeholder"
        :max-length="maxLength"
        :message-type="hasErrors ? 'error' : 'info'"
        show-character-count
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
