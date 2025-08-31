<script setup>
import { computed } from 'vue';
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
  variableType: {
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
  const examples = [...(props.modelValue.examples || [])];

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
  // Should start with a char, can end with a number or underscore - added global flag
  const regex = /\{\{([a-zA-Z][a-zA-Z0-9_]*)\}\}/g;
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
  const examples = Array.from(uniqueNames).map(name => ({
    name,
    value:
      props.modelValue.examples.find(ex => ex && ex.name === name)?.value || '',
  }));

  return {
    processedText: text, // Named variables don't need text processing
    examples,
    error,
  };
};

const parseVariables = text => {
  if (props.variableType === 'number') {
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

const updateNamedExample = (variableName, value) => {
  const newExamples = (props.modelValue.examples || []).map(ex =>
    ex && ex.name === variableName ? { ...ex, value } : ex
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
          {{
            variableType === 'number'
              ? t('SETTINGS.TEMPLATES.BUILDER.VARIABLES.NUMBER_HELP')
              : t('SETTINGS.TEMPLATES.BUILDER.VARIABLES.NAMED_HELP')
          }}
        </p>

        <!-- Number Variables -->
        <div v-if="variableType === 'number'" class="space-y-2">
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

        <!-- Named Variables -->
        <div v-if="variableType === 'named'" class="space-y-2">
          <div
            v-for="example in modelValue.examples"
            :key="`named-${example.name}`"
            class="flex items-center gap-3"
          >
            <span
              class="text-sm text-n-slate-11 min-w-[60px] flex items-center justify-center"
            >
              {{ formatNamedVariable(example.name) }}
            </span>

            <!-- Example Value Input -->
            <Input
              :model-value="example.value"
              :placeholder="
                t(
                  'SETTINGS.TEMPLATES.BUILDER.VARIABLES.NAMED_EXAMPLE_PLACEHOLDER',
                  { name: example.name }
                )
              "
              custom-input-class="flex-1 text-sm"
              @update:model-value="updateNamedExample(example.name, $event)"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
