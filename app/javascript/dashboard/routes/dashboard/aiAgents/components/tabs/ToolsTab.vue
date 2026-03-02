<script setup>
import { ref, reactive, onMounted, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import AiAgentsAPI from 'dashboard/api/saas/aiAgents';

const props = defineProps({
  agent: { type: Object, required: true },
});

const { t } = useI18n();

const tools = ref([]);
const isFetching = ref(false);
const isSubmitting = ref(false);
const dialogRef = ref(null);
const dialogMode = ref('create');
const editingTool = ref(null);

const form = reactive({
  name: '',
  description: '',
  toolType: 'http',
  url: '',
  method: 'GET',
  headers: '{}',
  bodyTemplate: '',
});

const toolTypeOptions = [
  { value: 'http', label: 'HTTP' },
  { value: 'handoff', label: 'Handoff' },
  { value: 'built_in', label: 'Built-in' },
];

const fetchTools = async () => {
  isFetching.value = true;
  try {
    const { data } = await AiAgentsAPI.getTools(props.agent.id);
    tools.value = data;
  } catch {
    useAlert(t('AI_AGENTS.TOOLS.FETCH_ERROR'));
  } finally {
    isFetching.value = false;
  }
};

const resetForm = () => {
  Object.assign(form, {
    name: '',
    description: '',
    toolType: 'http',
    url: '',
    method: 'GET',
    headers: '{}',
    bodyTemplate: '',
  });
};

const handleCreate = () => {
  dialogMode.value = 'create';
  editingTool.value = null;
  resetForm();
  nextTick(() => dialogRef.value?.open());
};

const handleEdit = tool => {
  dialogMode.value = 'edit';
  editingTool.value = tool;
  form.name = tool.name || '';
  form.description = tool.description || '';
  form.toolType = tool.tool_type || 'http';
  form.url = tool.config?.url || '';
  form.method = tool.config?.method || 'GET';
  form.headers = JSON.stringify(tool.config?.headers || {}, null, 2);
  form.bodyTemplate = tool.config?.body_template || '';
  nextTick(() => dialogRef.value?.open());
};

const handleSubmit = async () => {
  if (!form.name.trim()) return;
  isSubmitting.value = true;

  let parsedHeaders = {};
  try {
    parsedHeaders = JSON.parse(form.headers);
  } catch {
    // keep empty
  }

  const payload = {
    name: form.name,
    description: form.description,
    tool_type: form.toolType,
    config: {
      url: form.url,
      method: form.method,
      headers: parsedHeaders,
      body_template: form.bodyTemplate,
    },
  };

  try {
    if (dialogMode.value === 'edit' && editingTool.value) {
      const { data } = await AiAgentsAPI.updateTool(
        props.agent.id,
        editingTool.value.id,
        payload
      );
      const idx = tools.value.findIndex(item => item.id === data.id);
      if (idx !== -1) tools.value[idx] = data;
      useAlert(t('AI_AGENTS.TOOLS.EDIT.SUCCESS_MESSAGE'));
    } else {
      const { data } = await AiAgentsAPI.createTool(props.agent.id, payload);
      tools.value.push(data);
      useAlert(t('AI_AGENTS.TOOLS.CREATE.SUCCESS_MESSAGE'));
    }
    dialogRef.value?.close();
  } catch {
    useAlert(
      t(`AI_AGENTS.TOOLS.${dialogMode.value.toUpperCase()}.ERROR_MESSAGE`)
    );
  } finally {
    isSubmitting.value = false;
  }
};

const handleDelete = async tool => {
  try {
    await AiAgentsAPI.deleteTool(props.agent.id, tool.id);
    tools.value = tools.value.filter(item => item.id !== tool.id);
    useAlert(t('AI_AGENTS.TOOLS.DELETE.SUCCESS_MESSAGE'));
  } catch {
    useAlert(t('AI_AGENTS.TOOLS.DELETE.ERROR_MESSAGE'));
  }
};

onMounted(fetchTools);
</script>

<template>
  <div class="flex flex-col gap-6 max-w-3xl">
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-base font-medium text-n-slate-12">
          {{ t('AI_AGENTS.TABS.TOOLS') }}
        </h2>
        <p class="text-sm text-n-slate-11 mt-1">
          {{ t('AI_AGENTS.TOOLS.DESCRIPTION') }}
        </p>
      </div>
      <Button
        :label="t('AI_AGENTS.TOOLS.CREATE.TITLE')"
        icon="i-lucide-plus"
        size="sm"
        @click="handleCreate"
      />
    </div>

    <div
      v-if="isFetching"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>

    <div
      v-else-if="!tools.length"
      class="flex flex-col items-center py-12 gap-3"
    >
      <div class="i-lucide-wrench size-10 text-n-slate-8" />
      <p class="text-sm text-n-slate-11">
        {{ t('AI_AGENTS.TOOLS.EMPTY') }}
      </p>
    </div>

    <div v-else class="flex flex-col gap-4">
      <CardLayout v-for="tool in tools" :key="tool.id">
        <div class="flex items-start justify-between w-full">
          <div class="flex items-center gap-3 min-w-0">
            <div class="i-lucide-wrench size-5 text-n-slate-11 shrink-0" />
            <div class="min-w-0">
              <h3 class="text-sm font-medium text-n-slate-12 truncate">
                {{ tool.name }}
              </h3>
              <p class="text-xs text-n-slate-11 mt-0.5">
                {{ tool.description || '—' }}
              </p>
              <div class="flex items-center gap-2 mt-1">
                <span
                  class="px-1.5 py-0.5 text-xs rounded bg-n-alpha-2 text-n-slate-11"
                >
                  {{ tool.tool_type }}
                </span>
                <span
                  v-if="tool.config?.method"
                  class="px-1.5 py-0.5 text-xs rounded bg-n-alpha-2 text-n-slate-11"
                >
                  {{ tool.config.method }}
                </span>
              </div>
            </div>
          </div>
          <div class="flex items-center gap-1 shrink-0">
            <Button
              icon="i-lucide-pencil"
              variant="ghost"
              color="slate"
              size="xs"
              @click="handleEdit(tool)"
            />
            <Button
              icon="i-lucide-trash-2"
              variant="ghost"
              color="ruby"
              size="xs"
              @click="handleDelete(tool)"
            />
          </div>
        </div>
      </CardLayout>
    </div>

    <Dialog
      ref="dialogRef"
      type="edit"
      :title="t(`AI_AGENTS.TOOLS.${dialogMode.toUpperCase()}.TITLE`)"
      :show-cancel-button="false"
      :show-confirm-button="false"
      overflow-y-auto
      width="xl"
      @close="() => {}"
    >
      <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
        <Input
          v-model="form.name"
          :label="t('AI_AGENTS.TOOLS.FORM.NAME.LABEL')"
          :placeholder="t('AI_AGENTS.TOOLS.FORM.NAME.PLACEHOLDER')"
        />
        <Input
          v-model="form.description"
          :label="t('AI_AGENTS.TOOLS.FORM.DESCRIPTION.LABEL')"
          :placeholder="t('AI_AGENTS.TOOLS.FORM.DESCRIPTION.PLACEHOLDER')"
        />

        <fieldset class="flex flex-col gap-1.5">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('AI_AGENTS.TOOLS.FORM.TYPE.LABEL') }}
          </label>
          <select
            v-model="form.toolType"
            class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          >
            <option
              v-for="opt in toolTypeOptions"
              :key="opt.value"
              :value="opt.value"
            >
              {{ opt.label }}
            </option>
          </select>
        </fieldset>

        <template v-if="form.toolType === 'http'">
          <div class="flex gap-3">
            <fieldset class="flex flex-col gap-1.5 w-28">
              <label class="text-sm font-medium text-n-slate-12">
                {{ t('AI_AGENTS.TOOLS.FORM.METHOD_LABEL') }}
              </label>
              <select
                v-model="form.method"
                class="px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
              >
                <option value="GET">
                  {{ t('AI_AGENTS.TOOLS.FORM.METHODS.GET') }}
                </option>
                <option value="POST">
                  {{ t('AI_AGENTS.TOOLS.FORM.METHODS.POST') }}
                </option>
                <option value="PUT">
                  {{ t('AI_AGENTS.TOOLS.FORM.METHODS.PUT') }}
                </option>
                <option value="PATCH">
                  {{ t('AI_AGENTS.TOOLS.FORM.METHODS.PATCH') }}
                </option>
                <option value="DELETE">
                  {{ t('AI_AGENTS.TOOLS.FORM.METHODS.DELETE') }}
                </option>
              </select>
            </fieldset>
            <div class="flex-1">
              <Input
                v-model="form.url"
                label="URL"
                placeholder="https://api.example.com/endpoint"
              />
            </div>
          </div>

          <fieldset class="flex flex-col gap-1.5">
            <label class="text-sm font-medium text-n-slate-12">
              {{ t('AI_AGENTS.TOOLS.FORM.HEADERS') }}
            </label>
            <textarea
              v-model="form.headers"
              rows="3"
              class="w-full px-3 py-2 text-sm font-mono rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-blue-7 resize-none"
              placeholder='{ "Authorization": "Bearer ..." }'
            />
          </fieldset>

          <fieldset class="flex flex-col gap-1.5">
            <label class="text-sm font-medium text-n-slate-12">
              {{ t('AI_AGENTS.TOOLS.FORM.BODY_TEMPLATE') }}
            </label>
            <textarea
              v-model="form.bodyTemplate"
              rows="4"
              class="w-full px-3 py-2 text-sm font-mono rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-blue-7 resize-none"
              :placeholder="t('AI_AGENTS.TOOLS.FORM.BODY_PLACEHOLDER')"
            />
          </fieldset>
        </template>

        <div class="flex justify-end gap-2 pt-2">
          <Button
            type="button"
            variant="faded"
            color="slate"
            :label="t('AI_AGENTS.FORM.CANCEL')"
            @click="dialogRef?.close()"
          />
          <Button
            type="submit"
            :label="t(`AI_AGENTS.FORM.${dialogMode.toUpperCase()}`)"
            :is-loading="isSubmitting"
          />
        </div>
      </form>
      <template #footer />
    </Dialog>
  </div>
</template>
