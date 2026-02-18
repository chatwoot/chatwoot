<script>
import YCloudAPI from 'dashboard/api/ycloud';
import { useAlert } from 'dashboard/composables';
import SettingsSection from '../../../../../../components/SettingsSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: { SettingsSection, NextButton },
  props: {
    inbox: { type: Object, default: () => ({}) },
  },
  data() {
    return {
      flows: [],
      isLoading: false,
      showCreateModal: false,
      newFlow: { name: '', categories: ['CUSTOMER_SUPPORT'] },
    };
  },
  computed: {
    categoryOptions() {
      return ['CUSTOMER_SUPPORT', 'SURVEY', 'SIGN_UP', 'APPOINTMENT_BOOKING', 'LEAD_GENERATION', 'OTHER'];
    },
  },
  mounted() {
    this.fetchFlows();
  },
  methods: {
    async fetchFlows() {
      this.isLoading = true;
      try {
        const res = await YCloudAPI.listFlows(this.inbox.id);
        this.flows = res.data.items || res.data || [];
      } catch {
        useAlert(this.$t('YCLOUD.FLOWS.FETCH_ERROR'));
      }
      this.isLoading = false;
    },
    async createFlow() {
      try {
        await YCloudAPI.createFlow(this.inbox.id, this.newFlow);
        useAlert(this.$t('YCLOUD.FLOWS.CREATE_SUCCESS'));
        this.showCreateModal = false;
        this.newFlow = { name: '', categories: ['CUSTOMER_SUPPORT'] };
        this.fetchFlows();
      } catch {
        useAlert(this.$t('YCLOUD.FLOWS.CREATE_ERROR'));
      }
    },
    async publishFlow(flow) {
      try {
        await YCloudAPI.publishFlow(this.inbox.id, flow.id);
        useAlert(this.$t('YCLOUD.FLOWS.PUBLISH_SUCCESS'));
        this.fetchFlows();
      } catch {
        useAlert(this.$t('YCLOUD.FLOWS.PUBLISH_ERROR'));
      }
    },
    async deprecateFlow(flow) {
      try {
        await YCloudAPI.deprecateFlow(this.inbox.id, flow.id);
        useAlert(this.$t('YCLOUD.FLOWS.DEPRECATE_SUCCESS'));
        this.fetchFlows();
      } catch {
        useAlert(this.$t('YCLOUD.FLOWS.DEPRECATE_ERROR'));
      }
    },
    async deleteFlow(flow) {
      if (!window.confirm(this.$t('YCLOUD.FLOWS.DELETE_CONFIRM', { name: flow.name }))) return;
      try {
        await YCloudAPI.deleteFlow(this.inbox.id, flow.id);
        useAlert(this.$t('YCLOUD.FLOWS.DELETE_SUCCESS'));
        this.fetchFlows();
      } catch {
        useAlert(this.$t('YCLOUD.FLOWS.DELETE_ERROR'));
      }
    },
    async previewFlow(flow) {
      try {
        const res = await YCloudAPI.previewFlow(this.inbox.id, flow.id);
        if (res.data.previewUrl) {
          window.open(res.data.previewUrl, '_blank');
        }
      } catch {
        useAlert(this.$t('YCLOUD.FLOWS.PREVIEW_ERROR'));
      }
    },
    statusBadge(status) {
      const badges = {
        DRAFT: 'bg-yellow-100 text-yellow-800',
        PUBLISHED: 'bg-green-100 text-green-800',
        DEPRECATED: 'bg-n-slate-2 text-n-slate-11',
      };
      return badges[status] || 'bg-n-slate-2 text-n-slate-11';
    },
  },
};
</script>

<template>
  <div class="py-4">
    <SettingsSection
      :title="$t('YCLOUD.FLOWS.TITLE')"
      :sub-title="$t('YCLOUD.FLOWS.DESC')"
      :show-border="false"
    >
      <div class="flex justify-end mb-4">
        <NextButton
          :label="$t('YCLOUD.FLOWS.CREATE')"
          icon="i-lucide-plus"
          @click="showCreateModal = true"
        />
      </div>

      <div v-if="isLoading" class="text-center py-8"><span class="spinner" /></div>

      <div v-else-if="flows.length === 0" class="text-center py-8 text-n-slate-11">
        {{ $t('YCLOUD.FLOWS.EMPTY') }}
      </div>

      <div v-else class="space-y-3">
        <div
          v-for="flow in flows"
          :key="flow.id"
          class="p-4 bg-n-slate-1 rounded-lg flex items-center justify-between"
        >
          <div>
            <p class="font-semibold">{{ flow.name }}</p>
            <p class="text-sm text-n-slate-11">
              ID: {{ flow.id }}
              <span :class="statusBadge(flow.status)" class="ml-2 px-2 py-0.5 rounded text-xs font-medium">
                {{ flow.status }}
              </span>
            </p>
            <p v-if="flow.categories" class="text-xs text-n-slate-11 mt-1">
              {{ (flow.categories || []).join(', ') }}
            </p>
          </div>
          <div class="flex gap-2">
            <button
              v-if="flow.status === 'DRAFT'"
              class="text-green-600 text-sm hover:underline"
              @click="publishFlow(flow)"
            >{{ $t('YCLOUD.FLOWS.PUBLISH') }}</button>
            <button
              v-if="flow.status === 'PUBLISHED'"
              class="text-yellow-600 text-sm hover:underline"
              @click="deprecateFlow(flow)"
            >{{ $t('YCLOUD.FLOWS.DEPRECATE') }}</button>
            <button class="text-n-blue-text text-sm hover:underline" @click="previewFlow(flow)">
              {{ $t('YCLOUD.FLOWS.PREVIEW') }}
            </button>
            <button
              v-if="flow.status === 'DRAFT'"
              class="text-red-600 text-sm hover:underline"
              @click="deleteFlow(flow)"
            >{{ $t('YCLOUD.COMMON.DELETE') }}</button>
          </div>
        </div>
      </div>
    </SettingsSection>

    <!-- Create Flow Modal -->
    <div v-if="showCreateModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div class="bg-white rounded-xl p-6 w-full max-w-lg shadow-xl">
        <h3 class="text-lg font-semibold mb-4">{{ $t('YCLOUD.FLOWS.CREATE') }}</h3>
        <label class="block mb-3">
          {{ $t('YCLOUD.FLOWS.FLOW_NAME') }}
          <input v-model="newFlow.name" type="text" class="mt-1" />
        </label>
        <label class="block mb-3">
          {{ $t('YCLOUD.FLOWS.CATEGORIES') }}
          <select v-model="newFlow.categories[0]" class="mt-1">
            <option v-for="cat in categoryOptions" :key="cat" :value="cat">{{ cat }}</option>
          </select>
        </label>
        <div class="flex justify-end gap-2 mt-4">
          <NextButton :label="$t('YCLOUD.COMMON.CANCEL')" variant="ghost" @click="showCreateModal = false" />
          <NextButton :label="$t('YCLOUD.COMMON.SAVE')" @click="createFlow" />
        </div>
      </div>
    </div>
  </div>
</template>
