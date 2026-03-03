<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Select from 'dashboard/components-next/select/Select.vue';
import {
  FLOW_COMPONENT_TYPES,
  COMPONENT_LABELS,
  COMPONENT_ICONS,
  FLOW_ACTIONS,
  isInputComponent,
} from 'dashboard/helper/whatsappFlowHelper';

const props = defineProps({
  component: { type: Object, required: true },
  componentIndex: { type: Number, required: true },
  screens: { type: Array, required: true },
});

const emit = defineEmits(['update', 'close']);

const { t } = useI18n();

// ── Local editable copy ─────────────────────────────────────────────
const local = ref({});
const imageFileInput = ref(null);
const imagePreviewUrl = ref('');
const isUploadingImage = ref(false);

watch(
  () => props.component,
  val => {
    local.value = JSON.parse(JSON.stringify(val));
    if (val.type === FLOW_COMPONENT_TYPES.IMAGE && val.src) {
      imagePreviewUrl.value = val.src;
    }
  },
  { immediate: true, deep: true }
);

function emitUpdate() {
  emit('update', props.componentIndex, { ...local.value });
}

// ── Image file upload ───────────────────────────────────────────────
function triggerImageUpload() {
  imageFileInput.value?.click();
}

function handleImageFileSelect(event) {
  const file = event.target.files?.[0];
  if (!file) return;

  const validTypes = ['image/jpeg', 'image/png', 'image/webp'];
  if (!validTypes.includes(file.type)) {
    useAlert(t('WHATSAPP_FLOWS.PROPERTIES.IMAGE_INVALID_TYPE'));
    return;
  }

  // 5MB max
  const maxSize = 5 * 1024 * 1024;
  if (file.size > maxSize) {
    useAlert(t('WHATSAPP_FLOWS.PROPERTIES.IMAGE_TOO_LARGE'));
    return;
  }

  // Create a local preview via object URL
  isUploadingImage.value = true;
  const objectUrl = URL.createObjectURL(file);
  imagePreviewUrl.value = objectUrl;
  local.value.src = objectUrl;

  // Store the file reference for later upload when flow is saved
  // eslint-disable-next-line no-underscore-dangle
  local.value._imageFile = file;
  isUploadingImage.value = false;
  emitUpdate();
}

// ── Data source management (for Dropdown, Radio, Checkbox) ──────────
const hasDataSource = computed(() =>
  ['Dropdown', 'RadioButtonsGroup', 'CheckboxGroup'].includes(local.value.type)
);

function addOption() {
  if (!local.value['data-source']) {
    local.value['data-source'] = [];
  }
  const nextId = String(local.value['data-source'].length + 1);
  local.value['data-source'].push({ id: nextId, title: '' });
  emitUpdate();
}

function removeOption(index) {
  local.value['data-source'].splice(index, 1);
  emitUpdate();
}

function updateOption(index, field, value) {
  local.value['data-source'][index][field] = value;
  emitUpdate();
}

// ── Footer action config ────────────────────────────────────────────
const isFooter = computed(() => local.value.type === 'Footer');

const footerAction = computed({
  get: () => local.value['on-click-action']?.name || FLOW_ACTIONS.COMPLETE,
  set: val => {
    if (!local.value['on-click-action']) {
      local.value['on-click-action'] = {};
    }
    local.value['on-click-action'].name = val;
    if (val === FLOW_ACTIONS.NAVIGATE) {
      local.value['on-click-action'].next = local.value['on-click-action']
        .next || { type: 'screen', name: '' };
    } else {
      delete local.value['on-click-action'].next;
    }
    emitUpdate();
  },
});

const footerNextScreen = computed({
  get: () => local.value['on-click-action']?.next?.name || '',
  set: val => {
    if (!local.value['on-click-action']) {
      local.value['on-click-action'] = { name: FLOW_ACTIONS.NAVIGATE };
    }
    local.value['on-click-action'].next = { type: 'screen', name: val };
    emitUpdate();
  },
});

const otherScreens = computed(() =>
  props.screens.filter(s => s.id !== props.screens[0]?.id || true)
);

// ── Input type options ──────────────────────────────────────────────
const inputTypes = ['text', 'number', 'email', 'password', 'passcode', 'phone'];
const inputTypeOptions = inputTypes.map(it => ({ value: it, label: it }));

const scaleTypeOptions = computed(() => [
  { value: 'contain', label: t('WHATSAPP_FLOWS.PROPERTIES.SCALE_CONTAIN') },
  { value: 'cover', label: t('WHATSAPP_FLOWS.PROPERTIES.SCALE_COVER') },
]);

const footerActionOptions = computed(() => [
  {
    value: FLOW_ACTIONS.COMPLETE,
    label: t('WHATSAPP_FLOWS.PROPERTIES.ACTION_COMPLETE'),
  },
  {
    value: FLOW_ACTIONS.NAVIGATE,
    label: t('WHATSAPP_FLOWS.PROPERTIES.ACTION_NAVIGATE'),
  },
]);

const nextScreenOptions = computed(() =>
  otherScreens.value.map(s => ({
    value: s.id,
    label: `${s.title} (${s.id})`,
  }))
);
</script>

<template>
  <aside
    class="w-72 border-l border-n-weak bg-white flex flex-col overflow-hidden"
  >
    <!-- Header -->
    <div
      class="flex items-center justify-between px-4 py-3 border-b border-n-weak"
    >
      <div class="flex items-center gap-2">
        <span
          class="size-4 text-n-slate-9"
          :class="[COMPONENT_ICONS[local.type] || 'i-lucide-box']"
        />
        <span class="text-sm font-semibold text-n-slate-12">
          {{ COMPONENT_LABELS[local.type] || local.type }}
        </span>
      </div>
      <button
        class="p-1 rounded text-n-slate-9 hover:bg-n-alpha-1"
        @click="emit('close')"
      >
        <span class="i-lucide-x size-4" />
      </button>
    </div>

    <!-- Properties form -->
    <div class="flex-1 overflow-y-auto p-4 space-y-4">
      <!-- TEXT property (for display components) -->
      <div v-if="'text' in local && local.type !== 'Footer'" class="space-y-1">
        <label class="text-xs font-medium text-n-slate-11">
          {{ t('WHATSAPP_FLOWS.PROPERTIES.TEXT') }}
        </label>
        <textarea
          v-model="local.text"
          rows="3"
          class="w-full px-3 py-2 text-sm border border-n-weak rounded-lg resize-none focus:border-n-brand focus:ring-1 focus:ring-n-brand"
          @input="emitUpdate"
        />
      </div>

      <!-- LABEL property (for input components + Footer) -->
      <div v-if="'label' in local" class="space-y-1">
        <label class="text-xs font-medium text-n-slate-11">
          {{ t('WHATSAPP_FLOWS.PROPERTIES.LABEL') }}
        </label>
        <input
          v-model="local.label"
          type="text"
          class="w-full px-3 py-2 text-sm border border-n-weak rounded-lg focus:border-n-brand focus:ring-1 focus:ring-n-brand"
          @input="emitUpdate"
        />
      </div>

      <!-- NAME property (variable name for input components) -->
      <div v-if="isInputComponent(local.type)" class="space-y-1">
        <label class="text-xs font-medium text-n-slate-11">
          {{ t('WHATSAPP_FLOWS.PROPERTIES.VARIABLE_NAME') }}
        </label>
        <input
          v-model="local.name"
          type="text"
          class="w-full px-3 py-2 text-sm font-mono border border-n-weak rounded-lg focus:border-n-brand focus:ring-1 focus:ring-n-brand"
          @input="emitUpdate"
        />
        <p class="text-[10px] text-n-slate-9">
          {{ t('WHATSAPP_FLOWS.PROPERTIES.VARIABLE_NAME_HINT') }}
        </p>
      </div>

      <!-- REQUIRED toggle -->
      <div
        v-if="isInputComponent(local.type)"
        class="flex items-center justify-between"
      >
        <label class="text-xs font-medium text-n-slate-11">
          {{ t('WHATSAPP_FLOWS.PROPERTIES.REQUIRED') }}
        </label>
        <button
          class="relative inline-flex h-5 w-9 items-center rounded-full transition-colors"
          :class="local.required ? 'bg-n-brand' : 'bg-n-slate-4'"
          @click="
            local.required = !local.required;
            emitUpdate();
          "
        >
          <span
            class="inline-block size-3.5 transform rounded-full bg-white transition-transform"
            :class="local.required ? 'translate-x-[18px]' : 'translate-x-[3px]'"
          />
        </button>
      </div>

      <!-- INPUT TYPE (for TextInput) -->
      <div
        v-if="local.type === FLOW_COMPONENT_TYPES.TEXT_INPUT"
        class="space-y-1"
      >
        <label class="text-xs font-medium text-n-slate-11">
          {{ t('WHATSAPP_FLOWS.PROPERTIES.INPUT_TYPE') }}
        </label>
        <Select
          v-model="local['input-type']"
          :options="inputTypeOptions"
          class="w-full"
          @update:model-value="emitUpdate"
        />
      </div>

      <!-- HELPER TEXT -->
      <div v-if="'helper-text' in local" class="space-y-1">
        <label class="text-xs font-medium text-n-slate-11">
          {{ t('WHATSAPP_FLOWS.PROPERTIES.HELPER_TEXT') }}
        </label>
        <input
          v-model="local['helper-text']"
          type="text"
          class="w-full px-3 py-2 text-sm border border-n-weak rounded-lg focus:border-n-brand focus:ring-1 focus:ring-n-brand"
          @input="emitUpdate"
        />
      </div>

      <!-- IMAGE PROPERTIES -->
      <div v-if="local.type === FLOW_COMPONENT_TYPES.IMAGE" class="space-y-3">
        <!-- Image preview -->
        <div
          v-if="imagePreviewUrl"
          class="relative rounded-lg overflow-hidden border border-n-weak"
        >
          <img
            :src="imagePreviewUrl"
            alt=""
            class="w-full max-h-40 object-cover"
          />
          <button
            class="absolute top-1 right-1 p-1 rounded bg-n-solid-1/80 text-n-slate-9 hover:text-n-ruby-9"
            @click="
              imagePreviewUrl = '';
              local.src = '';
              emitUpdate();
            "
          >
            <span class="i-lucide-x size-3.5" />
          </button>
        </div>

        <!-- Upload button -->
        <div class="space-y-1">
          <label class="text-xs font-medium text-n-slate-11">
            {{ t('WHATSAPP_FLOWS.PROPERTIES.IMAGE_UPLOAD') }}
          </label>
          <button
            class="flex items-center justify-center gap-2 w-full px-3 py-2.5 text-sm border-2 border-dashed border-n-weak rounded-lg text-n-slate-9 hover:border-n-brand hover:text-n-brand transition-colors"
            :disabled="isUploadingImage"
            @click="triggerImageUpload"
          >
            <span class="i-lucide-upload size-4" />
            {{ t('WHATSAPP_FLOWS.PROPERTIES.CHOOSE_IMAGE') }}
          </button>
          <input
            ref="imageFileInput"
            type="file"
            accept="image/jpeg,image/png,image/webp"
            class="hidden"
            @change="handleImageFileSelect"
          />
          <p class="text-[10px] text-n-slate-9">
            {{ t('WHATSAPP_FLOWS.PROPERTIES.IMAGE_HINT') }}
          </p>
        </div>

        <!-- Or URL input -->
        <div class="space-y-1">
          <label class="text-xs font-medium text-n-slate-11">
            {{ t('WHATSAPP_FLOWS.PROPERTIES.IMAGE_URL') }}
          </label>
          <input
            v-model="local.src"
            type="url"
            :placeholder="t('WHATSAPP_FLOWS.PROPERTIES.IMAGE_URL_PLACEHOLDER')"
            class="w-full px-3 py-2 text-sm border border-n-weak rounded-lg focus:border-n-brand focus:ring-1 focus:ring-n-brand"
            @input="
              imagePreviewUrl = local.src;
              emitUpdate();
            "
          />
        </div>

        <!-- Height -->
        <div class="space-y-1">
          <label class="text-xs font-medium text-n-slate-11">
            {{ t('WHATSAPP_FLOWS.PROPERTIES.HEIGHT') }}
          </label>
          <input
            v-model.number="local.height"
            type="number"
            min="50"
            max="600"
            class="w-full px-3 py-2 text-sm border border-n-weak rounded-lg"
            @input="emitUpdate"
          />
        </div>

        <!-- Scale type -->
        <div class="space-y-1">
          <label class="text-xs font-medium text-n-slate-11">
            {{ t('WHATSAPP_FLOWS.PROPERTIES.SCALE_TYPE') }}
          </label>
          <Select
            v-model="local['scale-type']"
            :options="scaleTypeOptions"
            class="w-full"
            @update:model-value="emitUpdate"
          />
        </div>
      </div>

      <!-- DATA SOURCE (Dropdown, Radio, Checkbox) -->
      <div v-if="hasDataSource" class="space-y-2">
        <label class="text-xs font-medium text-n-slate-11">
          {{ t('WHATSAPP_FLOWS.PROPERTIES.OPTIONS') }}
        </label>
        <div
          v-for="(opt, idx) in local['data-source'] || []"
          :key="idx"
          class="flex items-center gap-2"
        >
          <input
            :value="opt.id"
            type="text"
            :placeholder="t('WHATSAPP_FLOWS.PROPERTIES.OPTION_ID')"
            class="w-16 px-2 py-1.5 text-xs border border-n-weak rounded-lg font-mono"
            @input="updateOption(idx, 'id', $event.target.value)"
          />
          <input
            :value="opt.title"
            type="text"
            :placeholder="t('WHATSAPP_FLOWS.PROPERTIES.OPTION_TITLE')"
            class="flex-1 px-2 py-1.5 text-xs border border-n-weak rounded-lg"
            @input="updateOption(idx, 'title', $event.target.value)"
          />
          <button
            class="p-1 rounded text-n-slate-9 hover:text-n-ruby-9"
            @click="removeOption(idx)"
          >
            <span class="i-lucide-x size-3" />
          </button>
        </div>
        <button
          class="flex items-center gap-1 text-xs text-n-brand hover:underline"
          @click="addOption"
        >
          <span class="i-lucide-plus size-3" />
          {{ t('WHATSAPP_FLOWS.PROPERTIES.ADD_OPTION') }}
        </button>
      </div>

      <!-- FOOTER ACTION CONFIG -->
      <div v-if="isFooter" class="space-y-3">
        <div class="space-y-1">
          <label class="text-xs font-medium text-n-slate-11">
            {{ t('WHATSAPP_FLOWS.PROPERTIES.ACTION') }}
          </label>
          <Select
            v-model="footerAction"
            :options="footerActionOptions"
            class="w-full"
          />
        </div>

        <div v-if="footerAction === FLOW_ACTIONS.NAVIGATE" class="space-y-1">
          <label class="text-xs font-medium text-n-slate-11">
            {{ t('WHATSAPP_FLOWS.PROPERTIES.NEXT_SCREEN') }}
          </label>
          <Select
            v-model="footerNextScreen"
            :options="nextScreenOptions"
            :placeholder="t('WHATSAPP_FLOWS.PROPERTIES.SELECT_SCREEN')"
            class="w-full"
          />
        </div>
      </div>
    </div>
  </aside>
</template>
