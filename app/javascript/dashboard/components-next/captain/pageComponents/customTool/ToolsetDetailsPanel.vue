<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { fetchToolsetDetails } from 'dashboard/api/captain/toolsCatalog';

import SidePanel from 'dashboard/components-next/side-panel/SidePanel.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Policy from 'dashboard/components/policy.vue';
import ToolsetIdentity from './ToolsetIdentity.vue';

const emit = defineEmits(['install']);

const { t } = useI18n();
const { formatMessage } = useMessageFormatter();
const {
  run: runDetailsRequest,
  abort: abortDetails,
  isPending: isLoading,
} = useAbortableRequest();

const panelRef = ref(null);
// The list entry renders the header right away while the details load
const toolset = ref(null);
const details = ref(null);
const hasError = ref(false);

const configurationFields = computed(() => [
  ...(details.value?.inputs || []),
  ...(details.value?.secrets || []).map(field => ({ ...field, secret: true })),
]);

const updatedAt = computed(() =>
  dynamicTime(Date.parse(toolset.value.updated_at) / 1000)
);

const loadDetails = async () => {
  hasError.value = false;
  try {
    const response = await runDetailsRequest(signal =>
      fetchToolsetDetails(toolset.value.detail_url, { signal })
    );
    if (response) details.value = response;
  } catch {
    hasError.value = true;
  }
};

const open = selectedToolset => {
  abortDetails();
  toolset.value = selectedToolset;
  details.value = null;
  panelRef.value.open();
  loadDetails();
};

const close = () => panelRef.value.close();

const install = () => {
  close();
  emit('install', toolset.value);
};

defineExpose({ open });
</script>

<template>
  <SidePanel ref="panelRef" width="2xl" @close="abortDetails">
    <template v-if="toolset" #header>
      <ToolsetIdentity :toolset="toolset" />
    </template>

    <div v-if="toolset" class="flex flex-col gap-6">
      <div class="flex flex-col gap-3">
        <p class="mb-0 text-sm text-n-slate-12">{{ toolset.description }}</p>
        <div
          class="flex flex-wrap items-center gap-x-2 gap-y-1 text-xs text-n-slate-11"
        >
          <span>{{ toolset.category }}</span>
          <span class="rounded-full size-1 bg-n-slate-8" />
          <span>
            {{
              t('CAPTAIN.CUSTOM_TOOLS.CATALOG.VERSION', {
                version: toolset.version,
              })
            }}
          </span>
          <span class="rounded-full size-1 bg-n-slate-8" />
          <span>
            {{ t('CAPTAIN.CUSTOM_TOOLS.CATALOG.UPDATED', { time: updatedAt }) }}
          </span>
        </div>
        <div v-if="details" class="flex flex-wrap gap-4 text-xs">
          <a
            :href="details.repository_url"
            target="_blank"
            rel="noopener noreferrer"
            class="inline-flex items-center gap-1 text-n-blue-11 hover:underline"
          >
            {{ t('CAPTAIN.CUSTOM_TOOLS.CATALOG.REPOSITORY') }}
            <i class="i-lucide-external-link size-3" />
          </a>
          <a
            :href="details.manifest_url"
            target="_blank"
            rel="noopener noreferrer"
            class="inline-flex items-center gap-1 text-n-blue-11 hover:underline"
          >
            {{ t('CAPTAIN.CUSTOM_TOOLS.CATALOG.MANIFEST') }}
            <i class="i-lucide-external-link size-3" />
          </a>
        </div>
      </div>

      <div v-if="isLoading" class="flex justify-center py-10">
        <Spinner />
      </div>

      <p v-else-if="hasError" class="mb-0 text-sm text-n-ruby-11">
        {{ t('CAPTAIN.CUSTOM_TOOLS.CATALOG.DETAILS_ERROR') }}
      </p>

      <template v-else-if="details">
        <section class="flex flex-col gap-2">
          <h4 class="text-sm font-medium text-n-slate-12">
            {{
              t('CAPTAIN.CUSTOM_TOOLS.CATALOG.TOOL_COUNT', {
                n: details.tools.length,
              })
            }}
          </h4>
          <ul class="flex flex-col gap-3 m-0 list-none">
            <li
              v-for="tool in details.tools"
              :key="tool.id"
              class="flex items-start gap-2"
            >
              <span
                class="px-1.5 py-0.5 text-xs font-mono rounded bg-n-alpha-2 text-n-slate-11 w-16 text-center shrink-0"
              >
                {{ tool.method }}
              </span>
              <div class="flex flex-col min-w-0 gap-0.5">
                <span class="text-sm text-n-slate-12">{{ tool.title }}</span>
                <span class="text-xs text-n-slate-11">
                  {{ tool.description }}
                </span>
              </div>
            </li>
          </ul>
        </section>

        <section v-if="configurationFields.length" class="flex flex-col gap-2">
          <h4 class="text-sm font-medium text-n-slate-12">
            {{ t('CAPTAIN.CUSTOM_TOOLS.CATALOG.CONFIGURATION') }}
          </h4>
          <ul class="flex flex-col gap-1.5 m-0 list-none">
            <li
              v-for="field in configurationFields"
              :key="`${field.secret}-${field.id}`"
              class="flex items-center gap-2 text-sm text-n-slate-12"
            >
              <i
                :class="
                  field.secret
                    ? 'i-lucide-key-round'
                    : 'i-lucide-sliders-horizontal'
                "
                class="size-3.5 shrink-0 text-n-slate-11"
              />
              <span class="truncate">{{ field.label }}</span>
              <span v-if="field.required" class="text-xs text-n-slate-10">
                {{ t('CAPTAIN.CUSTOM_TOOLS.CATALOG.REQUIRED') }}
              </span>
            </li>
          </ul>
        </section>

        <section v-if="details.readme" class="pt-6 border-t border-n-weak">
          <div
            v-dompurify-html="formatMessage(details.readme)"
            class="prose prose-sm max-w-none break-words text-n-slate-12 prose-headings:text-n-slate-12 prose-strong:text-n-slate-12 prose-code:text-n-slate-12 prose-a:text-n-blue-11 prose-p:my-2 prose-headings:mb-2 prose-headings:mt-4 prose-ul:my-2 prose-ol:my-2 prose-li:my-1"
          />
        </section>
      </template>
    </div>

    <template #footer>
      <div class="flex justify-end gap-3">
        <Button
          type="button"
          faded
          slate
          :label="t('GENERAL.CLOSE')"
          @click="close"
        />
        <Policy :permissions="['administrator']">
          <Button
            type="button"
            icon="i-lucide-download"
            :label="t('CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.INSTALL')"
            @click="install"
          />
        </Policy>
      </div>
    </template>
  </SidePanel>
</template>
