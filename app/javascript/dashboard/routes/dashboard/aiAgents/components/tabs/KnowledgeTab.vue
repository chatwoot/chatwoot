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

const knowledgeBases = ref([]);
const isFetching = ref(false);
const isCreating = ref(false);
const createDialogRef = ref(null);
const selectedKb = ref(null);

const newKb = reactive({ name: '', description: '' });
const newDoc = reactive({ sourceType: 'url', content: '' });

const fetchKnowledgeBases = async () => {
  isFetching.value = true;
  try {
    const { data } = await AiAgentsAPI.getKnowledgeBases(props.agent.id);
    knowledgeBases.value = data;
  } catch {
    useAlert(t('AI_AGENTS.KNOWLEDGE.FETCH_ERROR'));
  } finally {
    isFetching.value = false;
  }
};

const handleCreateKb = () => {
  newKb.name = '';
  newKb.description = '';
  nextTick(() => createDialogRef.value?.open());
};

const submitCreateKb = async () => {
  if (!newKb.name.trim()) return;
  isCreating.value = true;
  try {
    const { data } = await AiAgentsAPI.createKnowledgeBase(props.agent.id, {
      name: newKb.name,
      description: newKb.description,
    });
    knowledgeBases.value.push(data);
    useAlert(t('AI_AGENTS.KNOWLEDGE.CREATE.SUCCESS_MESSAGE'));
    createDialogRef.value?.close();
  } catch {
    useAlert(t('AI_AGENTS.KNOWLEDGE.CREATE.ERROR_MESSAGE'));
  } finally {
    isCreating.value = false;
  }
};

const handleDeleteKb = async kb => {
  try {
    await AiAgentsAPI.deleteKnowledgeBase(props.agent.id, kb.id);
    knowledgeBases.value = knowledgeBases.value.filter(k => k.id !== kb.id);
    useAlert(t('AI_AGENTS.KNOWLEDGE.DELETE.SUCCESS_MESSAGE'));
  } catch {
    useAlert(t('AI_AGENTS.KNOWLEDGE.DELETE.ERROR_MESSAGE'));
  }
};

const toggleExpandKb = kb => {
  selectedKb.value = selectedKb.value?.id === kb.id ? null : kb;
};

const handleAddDoc = async kb => {
  if (!newDoc.content.trim()) return;
  try {
    const { data } = await AiAgentsAPI.createDocument(props.agent.id, kb.id, {
      source_type: newDoc.sourceType,
      content: newDoc.content,
      title: newDoc.content.substring(0, 80),
    });
    const kbIndex = knowledgeBases.value.findIndex(k => k.id === kb.id);
    if (kbIndex !== -1) {
      const updated = { ...knowledgeBases.value[kbIndex] };
      updated.documents = [...(updated.documents || []), data];
      knowledgeBases.value[kbIndex] = updated;
    }
    newDoc.content = '';
    useAlert(t('AI_AGENTS.KNOWLEDGE.DOCUMENTS.CREATE.SUCCESS_MESSAGE'));
  } catch {
    useAlert(t('AI_AGENTS.KNOWLEDGE.DOCUMENTS.CREATE.ERROR_MESSAGE'));
  }
};

const handleDeleteDoc = async (kb, doc) => {
  try {
    await AiAgentsAPI.deleteDocument(props.agent.id, kb.id, doc.id);
    const kbIndex = knowledgeBases.value.findIndex(k => k.id === kb.id);
    if (kbIndex !== -1) {
      const updated = { ...knowledgeBases.value[kbIndex] };
      updated.documents = (updated.documents || []).filter(
        d => d.id !== doc.id
      );
      knowledgeBases.value[kbIndex] = updated;
    }
    useAlert(t('AI_AGENTS.KNOWLEDGE.DOCUMENTS.DELETE.SUCCESS_MESSAGE'));
  } catch {
    useAlert(t('AI_AGENTS.KNOWLEDGE.DOCUMENTS.DELETE.ERROR_MESSAGE'));
  }
};

const docStatusColor = status => {
  const map = {
    ready: 'bg-n-teal-9',
    processing: 'bg-n-amber-9',
    pending: 'bg-n-slate-8',
    error: 'bg-n-ruby-9',
  };
  return map[status] || 'bg-n-slate-8';
};

onMounted(fetchKnowledgeBases);
</script>

<template>
  <div class="flex flex-col gap-6 max-w-3xl">
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-base font-medium text-n-slate-12">
          {{ t('AI_AGENTS.TABS.KNOWLEDGE') }}
        </h2>
        <p class="text-sm text-n-slate-11 mt-1">
          {{ t('AI_AGENTS.KNOWLEDGE.DESCRIPTION') }}
        </p>
      </div>
      <Button
        :label="t('AI_AGENTS.KNOWLEDGE.CREATE.TITLE')"
        icon="i-lucide-plus"
        size="sm"
        @click="handleCreateKb"
      />
    </div>

    <div
      v-if="isFetching"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>

    <div
      v-else-if="!knowledgeBases.length"
      class="flex flex-col items-center py-12 gap-3"
    >
      <div class="i-lucide-database size-10 text-n-slate-8" />
      <p class="text-sm text-n-slate-11">
        {{ t('AI_AGENTS.KNOWLEDGE.EMPTY') }}
      </p>
    </div>

    <div v-else class="flex flex-col gap-4">
      <CardLayout v-for="kb in knowledgeBases" :key="kb.id">
        <div class="flex items-start justify-between w-full">
          <div
            class="flex items-center gap-3 cursor-pointer min-w-0"
            @click="toggleExpandKb(kb)"
          >
            <div class="i-lucide-database size-5 text-n-slate-11 shrink-0" />
            <div class="min-w-0">
              <h3 class="text-sm font-medium text-n-slate-12 truncate">
                {{ kb.name }}
              </h3>
              <p class="text-xs text-n-slate-11 mt-0.5">
                {{ kb.description || '—' }}
              </p>
            </div>
          </div>
          <div class="flex items-center gap-1 shrink-0">
            <Button
              :icon="
                selectedKb?.id === kb.id
                  ? 'i-lucide-chevron-up'
                  : 'i-lucide-chevron-down'
              "
              variant="ghost"
              color="slate"
              size="xs"
              @click="toggleExpandKb(kb)"
            />
            <Button
              icon="i-lucide-trash-2"
              variant="ghost"
              color="ruby"
              size="xs"
              @click="handleDeleteKb(kb)"
            />
          </div>
        </div>

        <template v-if="selectedKb?.id === kb.id" #after>
          <div class="border-t border-n-weak p-6 flex flex-col gap-4">
            <h4 class="text-sm font-medium text-n-slate-12">
              {{ t('AI_AGENTS.KNOWLEDGE.DOCUMENTS.TITLE') }}
            </h4>

            <div
              v-for="doc in kb.documents || []"
              :key="doc.id"
              class="flex items-center justify-between py-2 px-3 bg-n-alpha-1 rounded-lg"
            >
              <div class="flex items-center gap-2 min-w-0">
                <span
                  class="size-2 rounded-full shrink-0"
                  :class="docStatusColor(doc.status)"
                />
                <span class="text-sm text-n-slate-12 truncate">
                  {{ doc.title || doc.content?.substring(0, 60) }}
                </span>
                <span class="text-xs text-n-slate-10">
                  {{ doc.source_type }}
                </span>
              </div>
              <Button
                icon="i-lucide-x"
                variant="ghost"
                color="ruby"
                size="xs"
                @click="handleDeleteDoc(kb, doc)"
              />
            </div>

            <div class="flex gap-2 items-end">
              <fieldset class="flex flex-col gap-1 w-28">
                <label class="text-xs font-medium text-n-slate-11">
                  {{ t('AI_AGENTS.KNOWLEDGE.DOCUMENTS.SOURCE_TYPE') }}
                </label>
                <select
                  v-model="newDoc.sourceType"
                  class="px-2 py-1.5 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12"
                >
                  <option value="url">
                    {{ t('AI_AGENTS.KNOWLEDGE.DOCUMENT_TYPES.URL') }}
                  </option>
                  <option value="text">
                    {{ t('AI_AGENTS.KNOWLEDGE.DOCUMENT_TYPES.TEXT') }}
                  </option>
                  <option value="file_upload">
                    {{ t('AI_AGENTS.KNOWLEDGE.DOCUMENT_TYPES.FILE') }}
                  </option>
                </select>
              </fieldset>
              <div class="flex-1">
                <Input
                  v-model="newDoc.content"
                  :placeholder="
                    t('AI_AGENTS.KNOWLEDGE.DOCUMENTS.CONTENT_PLACEHOLDER')
                  "
                  size="sm"
                />
              </div>
              <Button
                icon="i-lucide-plus"
                size="sm"
                @click="handleAddDoc(kb)"
              />
            </div>
          </div>
        </template>
      </CardLayout>
    </div>

    <Dialog
      ref="createDialogRef"
      type="edit"
      :title="t('AI_AGENTS.KNOWLEDGE.CREATE.TITLE')"
      :show-cancel-button="false"
      :show-confirm-button="false"
      overflow-y-auto
      @close="() => {}"
    >
      <form class="flex flex-col gap-4" @submit.prevent="submitCreateKb">
        <Input
          v-model="newKb.name"
          :label="t('AI_AGENTS.KNOWLEDGE.FORM.NAME.LABEL')"
          :placeholder="t('AI_AGENTS.KNOWLEDGE.FORM.NAME.PLACEHOLDER')"
        />
        <Input
          v-model="newKb.description"
          :label="t('AI_AGENTS.KNOWLEDGE.FORM.DESCRIPTION.LABEL')"
          :placeholder="t('AI_AGENTS.KNOWLEDGE.FORM.DESCRIPTION.PLACEHOLDER')"
        />
        <div class="flex justify-end gap-2 pt-2">
          <Button
            type="button"
            variant="faded"
            color="slate"
            :label="t('AI_AGENTS.FORM.CANCEL')"
            @click="createDialogRef?.close()"
          />
          <Button
            type="submit"
            :label="t('AI_AGENTS.FORM.CREATE')"
            :is-loading="isCreating"
          />
        </div>
      </form>
      <template #footer />
    </Dialog>
  </div>
</template>
