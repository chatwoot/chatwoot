<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  modelValue: { type: Array, default: () => [] },
  actions: { type: Array, default: () => [] },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();

const BASE_FIELDS = [
  { key: 'name', label: 'Name' },
  { key: 'email', label: 'Email' },
  { key: 'phone', label: 'Phone' },
];

const FIELD_TYPES = [
  { value: 'text', label: 'CRM_FLOWS.FIELDS_BUILDER.TYPES.TEXT' },
  { value: 'number', label: 'CRM_FLOWS.FIELDS_BUILDER.TYPES.NUMBER' },
  { value: 'date', label: 'CRM_FLOWS.FIELDS_BUILDER.TYPES.DATE' },
  { value: 'select', label: 'CRM_FLOWS.FIELDS_BUILDER.TYPES.SELECT' },
  { value: 'boolean', label: 'CRM_FLOWS.FIELDS_BUILDER.TYPES.BOOLEAN' },
];

// Campos auto-sugeridos por tipo de acción
const ACTION_FIELD_SUGGESTIONS = {
  create_opportunity: [
    { key: 'amount', label: 'Amount', type: 'number', required: true },
    {
      key: 'stage',
      label: 'Stage',
      type: 'select',
      required: true,
      options: [
        'Prospecting',
        'Qualification',
        'Proposal',
        'Closed Won',
        'Closed Lost',
      ],
    },
  ],
  create_task: [
    { key: 'subject', label: 'Subject', type: 'text', required: true },
    { key: 'due_date', label: 'Due date', type: 'date', required: false },
  ],
  create_event: [
    { key: 'event_title', label: 'Title', type: 'text', required: true },
    { key: 'start_date', label: 'Start date', type: 'date', required: true },
  ],
  add_crm_tag: [
    { key: 'tag_name', label: 'Tag name', type: 'text', required: true },
  ],
  add_note: [
    { key: 'note_content', label: 'Content', type: 'text', required: true },
  ],
};

const fields = computed(() => props.modelValue);

function update(newFields) {
  emit('update:modelValue', newFields);
}

function slugify(label) {
  return label
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/(^_|_$)/g, '');
}

function addField() {
  update([
    ...fields.value,
    { key: '', label: '', type: 'text', required: true, options: null },
  ]);
}

function removeField(index) {
  update(fields.value.filter((_, i) => i !== index));
}

function updateFieldLabel(index, value) {
  const updated = fields.value.map((f, i) => {
    if (i !== index) return f;
    return { ...f, label: value, key: slugify(value) };
  });
  update(updated);
}

function updateFieldProp(index, prop, value) {
  const updated = fields.value.map((f, i) => {
    if (i !== index) return f;
    return { ...f, [prop]: value };
  });
  update(updated);
}

function addOption(index) {
  const field = fields.value[index];
  const options = field.options || [];
  update(
    fields.value.map((f, i) => {
      if (i !== index) return f;
      return { ...f, options: [...options, ''] };
    })
  );
}

function updateOption(fieldIndex, optionIndex, value) {
  update(
    fields.value.map((f, i) => {
      if (i !== fieldIndex) return f;
      const options = [...(f.options || [])];
      options[optionIndex] = value;
      return { ...f, options };
    })
  );
}

function removeOption(fieldIndex, optionIndex) {
  update(
    fields.value.map((f, i) => {
      if (i !== fieldIndex) return f;
      return {
        ...f,
        options: (f.options || []).filter((_, oi) => oi !== optionIndex),
      };
    })
  );
}

// Auto-suggest fields when actions change
const suggestedFields = computed(() => {
  const existing = new Set(fields.value.map(f => f.key));
  const suggestions = [];
  (props.actions || []).forEach(action => {
    const defs = ACTION_FIELD_SUGGESTIONS[action.action];
    if (defs) {
      defs.forEach(def => {
        if (
          !existing.has(def.key) &&
          !suggestions.some(s => s.key === def.key)
        ) {
          suggestions.push(def);
        }
      });
    }
  });
  return suggestions;
});

function applySuggestions() {
  update([...fields.value, ...suggestedFields.value]);
}
</script>

<template>
  <div class="flex flex-col gap-3">
    <h4 class="text-sm font-semibold text-n-slate-11">
      {{ $t('CRM_FLOWS.FIELDS_BUILDER.TITLE') }}
    </h4>

    <!-- Base fields (read-only) -->
    <div>
      <span class="text-xs text-n-slate-9 mb-1 block">{{
        $t('CRM_FLOWS.FIELDS_BUILDER.BASE_FIELDS_LABEL')
      }}</span>
      <div class="flex gap-1.5 flex-wrap">
        <span
          v-for="f in BASE_FIELDS"
          :key="f.key"
          class="text-xs bg-n-slate-3 text-n-slate-11 rounded-full px-2.5 py-0.5"
        >
          {{ f.label }}
        </span>
      </div>
    </div>

    <!-- Auto-suggest banner -->
    <div
      v-if="suggestedFields.length"
      class="border border-blue-200 bg-blue-50 rounded-lg p-2.5 flex items-center justify-between"
    >
      <span class="text-xs text-blue-700">
        {{ suggestedFields.length }} campo(s) sugerido(s) según las acciones
        configuradas
      </span>
      <button
        type="button"
        class="text-xs text-blue-600 hover:text-blue-800 font-semibold"
        @click="applySuggestions"
      >
        Añadir todos
      </button>
    </div>

    <!-- Custom fields table -->
    <div>
      <span class="text-xs text-n-slate-9 mb-1.5 block">{{
        $t('CRM_FLOWS.FIELDS_BUILDER.CUSTOM_FIELDS_LABEL')
      }}</span>

      <div
        v-for="(field, index) in fields"
        :key="index"
        class="border border-n-weak rounded-lg p-2.5 mb-2 flex flex-col gap-2"
      >
        <!-- Fila principal: label, tipo, requerido -->
        <div class="flex items-center gap-2">
          <input
            :value="field.label"
            type="text"
            :placeholder="$t('CRM_FLOWS.FIELDS_BUILDER.FIELD_LABEL')"
            class="flex-1 text-sm border border-n-weak rounded px-2 py-1.5 bg-n-solid-1 text-n-slate-12"
            @input="updateFieldLabel(index, $event.target.value)"
          />
          <select
            :value="field.type"
            class="w-24 text-sm border border-n-weak rounded px-1.5 py-1.5 bg-n-solid-1 text-n-slate-12"
            @change="updateFieldProp(index, 'type', $event.target.value)"
          >
            <option v-for="ft in FIELD_TYPES" :key="ft.value" :value="ft.value">
              {{ $t(ft.label) }}
            </option>
          </select>
          <label
            class="flex items-center gap-1 text-xs text-n-slate-9 select-none"
          >
            <input
              :checked="field.required"
              type="checkbox"
              class="w-3.5 h-3.5"
              @change="
                updateFieldProp(index, 'required', $event.target.checked)
              "
            />
            {{ $t('CRM_FLOWS.FIELDS_BUILDER.FIELD_REQUIRED') }}
          </label>
          <button
            type="button"
            class="text-n-slate-9 hover:text-red-500 transition-colors p-1"
            @click="removeField(index)"
          >
            <i class="i-lucide-x w-4 h-4" />
          </button>
        </div>

        <!-- Clave generada -->
        <span v-if="field.key" class="text-xs text-n-slate-9 ml-0">
          key: <code class="font-mono">{{ field.key }}</code>
        </span>

        <!-- Opciones (solo para tipo select) -->
        <div v-if="field.type === 'select'" class="flex flex-col gap-1">
          <div
            v-for="(opt, oi) in field.options || []"
            :key="oi"
            class="flex items-center gap-1.5"
          >
            <input
              :value="opt"
              type="text"
              placeholder="Opción..."
              class="flex-1 text-xs border border-n-weak rounded px-2 py-1 bg-n-solid-1 text-n-slate-12"
              @input="updateOption(index, oi, $event.target.value)"
            />
            <button
              type="button"
              class="text-n-slate-9 hover:text-red-500 p-0.5"
              @click="removeOption(index, oi)"
            >
              <i class="i-lucide-x w-3 h-3" />
            </button>
          </div>
          <button
            type="button"
            class="text-xs text-blue-600 hover:text-blue-700 text-left"
            @click="addOption(index)"
          >
            {{ $t('CRM_FLOWS.FIELDS_BUILDER.ADD_OPTION') }}
          </button>
        </div>
      </div>
    </div>

    <button
      type="button"
      class="text-sm text-blue-600 hover:text-blue-700 font-medium text-left"
      @click="addField"
    >
      {{ $t('CRM_FLOWS.FIELDS_BUILDER.ADD_FIELD') }}
    </button>
  </div>
</template>
