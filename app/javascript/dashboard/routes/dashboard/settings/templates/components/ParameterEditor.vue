<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  parameters: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['update:parameters']);

const { t } = useI18n();

// State
const editingParameter = ref(null);
const showAddModal = ref(false);

const parameterForm = ref({
  name: '',
  type: 'string',
  required: false,
  defaultValue: '',
  description: '',
  example: '',
});

const errors = ref({});

// Computed
const parametersList = computed(() => {
  return Object.entries(props.parameters).map(([name, config]) => ({
    name,
    ...config,
  }));
});

const typeOptions = [
  {
    value: 'string',
    label: t('TEMPLATES.BUILDER.PARAMETERS.TYPE.OPTIONS.STRING'),
  },
  {
    value: 'number',
    label: t('TEMPLATES.BUILDER.PARAMETERS.TYPE.OPTIONS.NUMBER'),
  },
  {
    value: 'boolean',
    label: t('TEMPLATES.BUILDER.PARAMETERS.TYPE.OPTIONS.BOOLEAN'),
  },
  { value: 'date', label: t('TEMPLATES.BUILDER.PARAMETERS.TYPE.OPTIONS.DATE') },
  {
    value: 'datetime',
    label: t('TEMPLATES.BUILDER.PARAMETERS.TYPE.OPTIONS.DATETIME'),
  },
  {
    value: 'array',
    label: t('TEMPLATES.BUILDER.PARAMETERS.TYPE.OPTIONS.ARRAY'),
  },
  {
    value: 'object',
    label: t('TEMPLATES.BUILDER.PARAMETERS.TYPE.OPTIONS.OBJECT'),
  },
];

// Methods
const openAddModal = () => {
  resetForm();
  editingParameter.value = null;
  showAddModal.value = true;
};

const openEditModal = parameter => {
  parameterForm.value = {
    name: parameter.name,
    type: parameter.type,
    required: parameter.required,
    defaultValue: parameter.default || '',
    description: parameter.description || '',
    example: parameter.example || '',
  };
  editingParameter.value = parameter.name;
  showAddModal.value = true;
};

const resetForm = () => {
  parameterForm.value = {
    name: '',
    type: 'string',
    required: false,
    defaultValue: '',
    description: '',
    example: '',
  };
  errors.value = {};
};

const validateParameter = () => {
  errors.value = {};

  if (!parameterForm.value.name.trim()) {
    errors.value.name = t(
      'TEMPLATES.BUILDER.VALIDATION.PARAMETER_NAME_REQUIRED'
    );
    return false;
  }

  // Check for valid parameter name (no spaces, alphanumeric + underscore)
  if (!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(parameterForm.value.name)) {
    errors.value.name =
      'Parameter name must be alphanumeric and start with a letter';
    return false;
  }

  // Check for duplicate (only if not editing or name changed)
  if (
    editingParameter.value !== parameterForm.value.name &&
    props.parameters[parameterForm.value.name]
  ) {
    errors.value.name = t('TEMPLATES.BUILDER.VALIDATION.DUPLICATE_PARAMETER');
    return false;
  }

  if (!parameterForm.value.type) {
    errors.value.type = t(
      'TEMPLATES.BUILDER.VALIDATION.PARAMETER_TYPE_REQUIRED'
    );
    return false;
  }

  return true;
};

const saveParameter = () => {
  if (!validateParameter()) {
    return;
  }

  const updatedParameters = { ...props.parameters };

  // If editing and name changed, remove old key
  if (
    editingParameter.value &&
    editingParameter.value !== parameterForm.value.name
  ) {
    delete updatedParameters[editingParameter.value];
  }

  updatedParameters[parameterForm.value.name] = {
    type: parameterForm.value.type,
    required: parameterForm.value.required,
    default: parameterForm.value.defaultValue || undefined,
    description: parameterForm.value.description || undefined,
    example: parameterForm.value.example || undefined,
  };

  emit('update:parameters', updatedParameters);
  showAddModal.value = false;
  resetForm();
};

const deleteParameter = name => {
  const updatedParameters = { ...props.parameters };
  delete updatedParameters[name];
  emit('update:parameters', updatedParameters);
};

const closeModal = () => {
  showAddModal.value = false;
  resetForm();
};

const getTypeLabel = type => {
  const option = typeOptions.find(opt => opt.value === type);
  return option ? option.label : type;
};
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex items-start justify-between">
      <div>
        <h3 class="text-lg font-semibold text-n-slate-12">
          {{ t('TEMPLATES.BUILDER.PARAMETERS.TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11 mt-1">
          {{ t('TEMPLATES.BUILDER.PARAMETERS.DESCRIPTION') }}
        </p>
      </div>
      <Button
        icon="i-lucide-plus"
        :label="t('TEMPLATES.BUILDER.PARAMETERS.ADD')"
        @click="openAddModal"
      />
    </div>

    <!-- Parameters List -->
    <div
      v-if="parametersList.length === 0"
      class="text-center py-12 bg-n-slate-2 rounded-lg"
    >
      <i class="i-lucide-braces text-4xl text-n-slate-8 mb-3" />
      <p class="text-sm text-n-slate-11">
        {{ t('TEMPLATES.BUILDER.PARAMETERS.EMPTY') }}
      </p>
    </div>

    <div v-else class="space-y-3">
      <div
        v-for="param in parametersList"
        :key="param.name"
        class="flex items-start gap-4 p-4 bg-white border border-n-slate-7 rounded-lg hover:shadow-sm transition-shadow"
      >
        <div class="flex-1">
          <div class="flex items-center gap-3 mb-2">
            <code
              class="text-sm font-mono font-medium text-n-blue-11 bg-n-blue-2 px-2 py-1 rounded"
            >
              {{ param.name }}
            </code>
            <span
              class="text-xs px-2 py-1 bg-n-slate-3 text-n-slate-11 rounded"
            >
              {{ getTypeLabel(param.type) }}
            </span>
            <span
              v-if="param.required"
              class="text-xs px-2 py-1 bg-n-red-3 text-n-red-11 rounded font-medium"
            >
              Required
            </span>
          </div>

          <p v-if="param.description" class="text-sm text-n-slate-11 mb-2">
            {{ param.description }}
          </p>

          <div class="flex gap-4 text-xs text-n-slate-10">
            <div v-if="param.default">
              <span class="font-medium">Default:</span>
              <code class="ml-1 px-1 bg-n-slate-2 rounded">{{
                param.default
              }}</code>
            </div>
            <div v-if="param.example">
              <span class="font-medium">Example:</span>
              <code class="ml-1 px-1 bg-n-slate-2 rounded">{{
                param.example
              }}</code>
            </div>
          </div>
        </div>

        <div class="flex gap-1">
          <Button
            icon="i-lucide-pen"
            slate
            xs
            faded
            @click="openEditModal(param)"
          />
          <Button
            icon="i-lucide-trash-2"
            ruby
            xs
            faded
            @click="deleteParameter(param.name)"
          />
        </div>
      </div>
    </div>

    <!-- Add/Edit Modal -->
    <woot-modal v-model:show="showAddModal" :on-close="closeModal">
      <div class="w-full max-w-2xl p-6">
        <h3 class="text-xl font-semibold text-n-slate-12 mb-6">
          {{
            editingParameter
              ? 'Edit Parameter'
              : t('TEMPLATES.BUILDER.PARAMETERS.ADD')
          }}
        </h3>

        <div class="space-y-4">
          <!-- Parameter Name -->
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-2">
              {{ t('TEMPLATES.BUILDER.PARAMETERS.NAME.LABEL') }}
              <span class="text-n-red-11">*</span>
            </label>
            <input
              v-model="parameterForm.name"
              type="text"
              :placeholder="t('TEMPLATES.BUILDER.PARAMETERS.NAME.PLACEHOLDER')"
              class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 font-mono"
              :class="[
                errors.name
                  ? 'border-n-red-7 focus:ring-n-red-7'
                  : 'border-n-slate-7 focus:ring-n-blue-7',
              ]"
            />
            <p v-if="errors.name" class="mt-1 text-sm text-n-red-11">
              {{ errors.name }}
            </p>
            <p class="mt-1 text-xs text-n-slate-10">
              Use lowercase with underscores (e.g., customer_name, order_total)
            </p>
          </div>

          <!-- Type and Required -->
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-2">
                {{ t('TEMPLATES.BUILDER.PARAMETERS.TYPE.LABEL') }}
                <span class="text-n-red-11">*</span>
              </label>
              <select
                v-model="parameterForm.type"
                class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2"
                :class="[
                  errors.type
                    ? 'border-n-red-7 focus:ring-n-red-7'
                    : 'border-n-slate-7 focus:ring-n-blue-7',
                ]"
              >
                <option
                  v-for="option in typeOptions"
                  :key="option.value"
                  :value="option.value"
                >
                  {{ option.label }}
                </option>
              </select>
              <p v-if="errors.type" class="mt-1 text-sm text-n-red-11">
                {{ errors.type }}
              </p>
            </div>

            <div class="flex items-end">
              <label class="flex items-center gap-2 cursor-pointer">
                <input
                  v-model="parameterForm.required"
                  type="checkbox"
                  class="w-4 h-4 rounded border-n-slate-7 text-n-blue-9 focus:ring-2 focus:ring-n-blue-7"
                />
                <span class="text-sm font-medium text-n-slate-12">
                  {{ t('TEMPLATES.BUILDER.PARAMETERS.REQUIRED.LABEL') }}
                </span>
              </label>
            </div>
          </div>

          <!-- Default Value -->
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-2">
              {{ t('TEMPLATES.BUILDER.PARAMETERS.DEFAULT.LABEL') }}
            </label>
            <input
              v-model="parameterForm.defaultValue"
              type="text"
              :placeholder="
                t('TEMPLATES.BUILDER.PARAMETERS.DEFAULT.PLACEHOLDER')
              "
              class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            />
          </div>

          <!-- Description -->
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-2">
              {{ t('TEMPLATES.BUILDER.PARAMETERS.DESCRIPTION_LABEL.LABEL') }}
            </label>
            <textarea
              v-model="parameterForm.description"
              rows="2"
              :placeholder="
                t('TEMPLATES.BUILDER.PARAMETERS.DESCRIPTION_LABEL.PLACEHOLDER')
              "
              class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            />
          </div>

          <!-- Example -->
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-2">
              {{ t('TEMPLATES.BUILDER.PARAMETERS.EXAMPLE.LABEL') }}
            </label>
            <input
              v-model="parameterForm.example"
              type="text"
              :placeholder="
                t('TEMPLATES.BUILDER.PARAMETERS.EXAMPLE.PLACEHOLDER')
              "
              class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7 font-mono text-sm"
            />
          </div>
        </div>

        <!-- Modal Actions -->
        <div class="flex justify-end gap-3 mt-6">
          <Button variant="outline" slate @click="closeModal"> Cancel </Button>
          <Button @click="saveParameter">
            {{ editingParameter ? 'Update' : 'Add' }} Parameter
          </Button>
        </div>
      </div>
    </woot-modal>
  </div>
</template>
