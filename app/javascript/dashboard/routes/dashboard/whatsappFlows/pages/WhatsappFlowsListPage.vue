<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Select from 'dashboard/components-next/select/Select.vue';

const { t } = useI18n();
const store = useStore();
const router = useRouter();

const selectedInboxId = ref('');
const showDeleteConfirm = ref(false);
const flowToDelete = ref(null);

const uiFlags = computed(() => store.getters['whatsappFlows/getUIFlags']);
const flows = computed(() => {
  const all = store.getters['whatsappFlows/getWhatsappFlows'];
  if (selectedInboxId.value) {
    return all.filter(f => f.inbox_id === selectedInboxId.value);
  }
  return all;
});

const whatsappInboxes = computed(() =>
  store.getters['inboxes/getInboxes'].filter(
    inbox => inbox.channel_type === 'Channel::Whatsapp'
  )
);
const inboxOptions = computed(() => [
  { value: '', label: t('WHATSAPP_FLOWS.LIST.ALL_INBOXES') },
  ...whatsappInboxes.value.map(i => ({ value: i.id, label: i.name })),
]);

onMounted(() => {
  store.dispatch('whatsappFlows/get');
  store.dispatch('inboxes/get');
});

function navigateToBuilder() {
  router.push({ name: 'whatsapp_flows_new' });
}

function editFlow(flow) {
  router.push({
    name: 'whatsapp_flows_edit',
    params: { flowId: flow.id },
  });
}

function confirmDelete(flow) {
  flowToDelete.value = flow;
  showDeleteConfirm.value = true;
}

async function deleteFlow() {
  try {
    await store.dispatch('whatsappFlows/delete', flowToDelete.value.id);
    useAlert(t('WHATSAPP_FLOWS.LIST.DELETE_SUCCESS'));
  } catch {
    useAlert(t('WHATSAPP_FLOWS.LIST.DELETE_ERROR'));
  } finally {
    showDeleteConfirm.value = false;
    flowToDelete.value = null;
  }
}

async function publishFlow(flow) {
  try {
    await store.dispatch('whatsappFlows/publish', flow.id);
    useAlert(t('WHATSAPP_FLOWS.LIST.PUBLISH_SUCCESS'));
  } catch {
    useAlert(t('WHATSAPP_FLOWS.LIST.PUBLISH_ERROR'));
  }
}

function statusBadgeClass(status) {
  const classes = {
    draft: 'bg-n-amber-2 text-n-amber-11',
    published: 'bg-n-teal-2 text-n-teal-11',
    deprecated: 'bg-n-slate-2 text-n-slate-11',
    blocked: 'bg-n-ruby-2 text-n-ruby-11',
    throttled: 'bg-n-amber-2 text-n-amber-11',
  };
  return classes[status] || classes.draft;
}
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1">
    <!-- Header -->
    <header
      class="flex items-center justify-between px-6 py-4 border-b border-n-weak"
    >
      <div>
        <h1 class="text-xl font-semibold text-n-slate-12">
          {{ t('WHATSAPP_FLOWS.TITLE') }}
        </h1>
        <p class="text-sm text-n-slate-11 mt-1">
          {{ t('WHATSAPP_FLOWS.DESCRIPTION') }}
        </p>
      </div>
      <div class="flex items-center gap-3">
        <Select v-model="selectedInboxId" :options="inboxOptions" />
        <button
          class="flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-n-brand rounded-lg hover:bg-n-brand-dark"
          @click="navigateToBuilder"
        >
          <span class="i-lucide-plus size-4" />
          {{ t('WHATSAPP_FLOWS.LIST.CREATE') }}
        </button>
      </div>
    </header>

    <!-- Content -->
    <main class="flex-1 px-6 overflow-y-auto">
      <!-- Loading state -->
      <div
        v-if="uiFlags.isFetching"
        class="flex items-center justify-center py-20"
      >
        <span class="i-lucide-loader-2 size-8 animate-spin text-n-slate-9" />
      </div>

      <!-- Empty state -->
      <div
        v-else-if="flows.length === 0"
        class="flex flex-col items-center justify-center py-20 gap-4"
      >
        <span class="i-lucide-git-branch size-16 text-n-slate-7" />
        <p class="text-n-slate-11 text-sm">
          {{ t('WHATSAPP_FLOWS.LIST.EMPTY') }}
        </p>
        <button
          class="px-4 py-2 text-sm font-medium text-white bg-n-brand rounded-lg hover:bg-n-brand-dark"
          @click="navigateToBuilder"
        >
          {{ t('WHATSAPP_FLOWS.LIST.CREATE_FIRST') }}
        </button>
      </div>

      <!-- Flow list -->
      <div v-else class="py-4 space-y-3">
        <div
          v-for="flow in flows"
          :key="flow.id"
          class="flex items-center justify-between p-4 bg-white rounded-xl border border-n-weak hover:border-n-brand-subtle transition-colors"
        >
          <div class="flex items-center gap-4 flex-1 min-w-0">
            <div
              class="flex items-center justify-center size-10 rounded-lg bg-n-violet-2"
            >
              <span class="i-lucide-git-branch size-5 text-n-violet-11" />
            </div>
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2">
                <h3 class="text-sm font-medium text-n-slate-12 truncate">
                  {{ flow.name }}
                </h3>
                <span
                  :class="statusBadgeClass(flow.status)"
                  class="px-2 py-0.5 text-xs font-medium rounded-full capitalize"
                >
                  {{ flow.status }}
                </span>
              </div>
              <p class="text-xs text-n-slate-9 mt-0.5">
                {{ flow.flow_json?.screens?.length || 0 }}
                {{ t('WHATSAPP_FLOWS.LIST.SCREENS') }}
                <span v-if="flow.flow_id" class="ml-2">
                  ID: {{ flow.flow_id }}
                </span>
              </p>
            </div>
          </div>

          <div class="flex items-center gap-2 ml-4">
            <button
              v-if="flow.status === 'draft'"
              class="p-2 rounded-lg text-n-slate-9 hover:text-n-brand hover:bg-n-brand-subtle transition-colors"
              :title="t('WHATSAPP_FLOWS.LIST.PUBLISH')"
              @click="publishFlow(flow)"
            >
              <span class="i-lucide-send size-4" />
            </button>
            <button
              class="p-2 rounded-lg text-n-slate-9 hover:text-n-brand hover:bg-n-brand-subtle transition-colors"
              :title="t('WHATSAPP_FLOWS.LIST.EDIT')"
              @click="editFlow(flow)"
            >
              <span class="i-lucide-pencil size-4" />
            </button>
            <button
              class="p-2 rounded-lg text-n-slate-9 hover:text-n-ruby-9 hover:bg-n-ruby-2 transition-colors"
              :title="t('WHATSAPP_FLOWS.LIST.DELETE')"
              @click="confirmDelete(flow)"
            >
              <span class="i-lucide-trash-2 size-4" />
            </button>
          </div>
        </div>
      </div>
    </main>

    <!-- Delete confirmation dialog -->
    <div
      v-if="showDeleteConfirm"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
    >
      <div class="bg-white rounded-xl p-6 max-w-sm w-full mx-4 shadow-lg">
        <h3 class="text-base font-semibold text-n-slate-12">
          {{ t('WHATSAPP_FLOWS.LIST.DELETE_CONFIRM_TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11 mt-2">
          {{ t('WHATSAPP_FLOWS.LIST.DELETE_CONFIRM_DESC') }}
        </p>
        <div class="flex justify-end gap-3 mt-6">
          <button
            class="px-4 py-2 text-sm rounded-lg border border-n-weak hover:bg-n-alpha-1"
            @click="showDeleteConfirm = false"
          >
            {{ t('WHATSAPP_FLOWS.LIST.CANCEL') }}
          </button>
          <button
            class="px-4 py-2 text-sm text-white bg-n-ruby-9 rounded-lg hover:bg-n-ruby-10"
            @click="deleteFlow"
          >
            {{ t('WHATSAPP_FLOWS.LIST.DELETE') }}
          </button>
        </div>
      </div>
    </div>
  </section>
</template>
