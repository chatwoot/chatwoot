<script>
import { mapGetters, mapActions } from 'vuex';
import { useAlert } from 'dashboard/composables';
import PageHeader from '../SettingsSubPageHeader.vue';
import FlowBuilderEditor from './FlowBuilderEditor.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  name: 'FlowBuilder',
  components: {
    PageHeader,
    FlowBuilderEditor,
    NextButton,
  },
  data() {
    return {
      view: 'list', // 'list' | 'editor'
      editingFlow: null,
      isNew: false,
    };
  },
  computed: {
    ...mapGetters({
      flows: 'conversationFlows/getFlows',
      uiFlags: 'conversationFlows/getUIFlags',
    }),
  },
  mounted() {
    this.fetchFlows();
  },
  methods: {
    ...mapActions('conversationFlows', [
      'fetchFlows',
      'deleteFlow',
      'toggleFlow',
    ]),
    openNew() {
      this.editingFlow = null;
      this.isNew = true;
      this.view = 'editor';
    },
    openEdit(flow) {
      this.editingFlow = flow;
      this.isNew = false;
      this.view = 'editor';
    },
    onEditorClose() {
      this.view = 'list';
      this.editingFlow = null;
    },
    onEditorSaved() {
      this.view = 'list';
      this.editingFlow = null;
      this.fetchFlows();
    },
    async handleDelete(flow) {
      try {
        await this.deleteFlow(flow.id);
        useAlert('Flow deleted');
      } catch (error) {
        useAlert(error.message || 'Failed to delete');
      }
    },
    async handleToggle(flow) {
      try {
        await this.toggleFlow(flow.id);
      } catch (error) {
        useAlert(error.message || 'Failed to toggle');
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-full overflow-hidden">
    <!-- List View -->
    <template v-if="view === 'list'">
      <PageHeader
        :header-title="$t('FLOW_BUILDER.TITLE')"
        :header-content="$t('FLOW_BUILDER.DESC')"
      />
      <div class="flex-1 px-6 py-4 overflow-y-auto">
        <NextButton
          class="mb-4"
          solid
          blue
          :label="$t('FLOW_BUILDER.ADD_BUTTON')"
          @click="openNew"
        />

        <div class="space-y-3">
          <div
            v-for="flow in flows"
            :key="flow.id"
            class="flex items-center justify-between p-4 border rounded-lg border-n-slate-6"
          >
            <div class="flex items-center gap-3">
              <button
                class="w-10 h-6 rounded-full relative transition-colors"
                :class="flow.enabled ? 'bg-n-brand' : 'bg-n-slate-4'"
                @click="handleToggle(flow)"
              >
                <span
                  class="absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform"
                  :class="flow.enabled ? 'translate-x-4' : 'translate-x-0.5'"
                />
              </button>
              <div>
                <div class="font-medium text-n-slate-12">{{ flow.name }}</div>
                <div class="text-xs text-n-slate-10">
                  {{ (flow.flow_data?.nodes || []).length }} nodes
                  {{ flow.execution_count > 0 ? `• ${flow.execution_count} runs` : '' }}
                </div>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <NextButton ghost :label="$t('FLOW_BUILDER.EDIT')" @click="openEdit(flow)" />
              <NextButton ghost red :label="$t('FLOW_BUILDER.DELETE.BUTTON')" @click="handleDelete(flow)" />
            </div>
          </div>
          <div v-if="flows.length === 0" class="text-center py-12 text-n-slate-10 text-sm">
            No flows yet. Create one to automate your conversations.
          </div>
        </div>
      </div>
    </template>

    <!-- Editor View -->
    <FlowBuilderEditor
      v-else
      :flow="editingFlow"
      :is-new="isNew"
      @close="onEditorClose"
      @saved="onEditorSaved"
    />
  </div>
</template>
