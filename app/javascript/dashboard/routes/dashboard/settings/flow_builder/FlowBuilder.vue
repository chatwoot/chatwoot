<script>
import { mapGetters, mapActions } from 'vuex';
import { useAlert } from 'dashboard/composables';
import PageHeader from '../SettingsSubPageHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  name: 'FlowBuilder',
  components: {
    PageHeader,
    NextButton,
  },
  data() {
    return {
      showEditor: false,
      editingFlow: null,
      form: {
        name: '',
        description: '',
        flow_data: { nodes: [], edges: [] },
        enabled: false,
      },
      selectedNode: null,
      nodeTypes: [
        { value: 'trigger', label: 'Trigger', icon: 'play' },
        { value: 'condition', label: 'Condition', icon: 'branch' },
        { value: 'action', label: 'Action', icon: 'zap' },
        { value: 'ai_reply', label: 'AI Reply', icon: 'bot' },
        { value: 'send_message', label: 'Send Message', icon: 'message' },
      ],
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
      'createFlow',
      'updateFlow',
      'deleteFlow',
      'toggleFlow',
    ]),
    openEditor(flow = null) {
      if (flow) {
        this.editingFlow = flow;
        this.form = {
          name: flow.name,
          description: flow.description || '',
          flow_data: JSON.parse(JSON.stringify(flow.flow_data || { nodes: [], edges: [] })),
          enabled: flow.enabled,
        };
      } else {
        this.editingFlow = null;
        this.form = {
          name: '',
          description: '',
          flow_data: { nodes: [], edges: [] },
          enabled: false,
        };
      }
      this.showEditor = true;
    },
    addNode(type) {
      const id = `node_${Date.now()}`;
      const node = { id, type, data: this.defaultNodeData(type) };
      this.form.flow_data.nodes.push(node);
    },
    defaultNodeData(type) {
      switch (type) {
        case 'trigger': return { event: 'conversation_created' };
        case 'condition': return { field: 'inbox_id', operator: 'equals', value: '' };
        case 'action': return { action: 'assign_agent', agent_id: '' };
        case 'ai_reply': return { prompt: 'Welcome message' };
        case 'send_message': return { content: '' };
        default: return {};
      }
    },
    removeNode(nodeId) {
      this.form.flow_data.nodes = this.form.flow_data.nodes.filter(n => n.id !== nodeId);
      this.form.flow_data.edges = this.form.flow_data.edges.filter(e => e.source !== nodeId && e.target !== nodeId);
    },
    async saveFlow() {
      try {
        if (this.editingFlow) {
          await this.updateFlow({ id: this.editingFlow.id, ...this.form });
          useAlert(this.$t('FLOW_BUILDER.UPDATE.SUCCESS'));
        } else {
          await this.createFlow(this.form);
          useAlert(this.$t('FLOW_BUILDER.CREATE.SUCCESS'));
        }
        this.showEditor = false;
      } catch (error) {
        useAlert(error.message || this.$t('FLOW_BUILDER.ERROR'));
      }
    },
    async handleDelete(flow) {
      try {
        await this.deleteFlow(flow.id);
        useAlert(this.$t('FLOW_BUILDER.DELETE.SUCCESS'));
      } catch (error) {
        useAlert(error.message || this.$t('FLOW_BUILDER.ERROR'));
      }
    },
    async handleToggle(flow) {
      try {
        await this.toggleFlow(flow.id);
      } catch (error) {
        useAlert(error.message || this.$t('FLOW_BUILDER.ERROR'));
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-full overflow-auto">
    <PageHeader
      :header-title="$t('FLOW_BUILDER.TITLE')"
      :header-content="$t('FLOW_BUILDER.DESC')"
    />
    <div class="flex-1 px-6 py-4">
      <NextButton
        class="mb-4"
        solid
        blue
        :label="$t('FLOW_BUILDER.ADD_BUTTON')"
        @click="openEditor()"
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
            <NextButton ghost :label="$t('FLOW_BUILDER.EDIT')" @click="openEditor(flow)" />
            <NextButton ghost red :label="$t('FLOW_BUILDER.DELETE.BUTTON')" @click="handleDelete(flow)" />
          </div>
        </div>
      </div>

      <!-- Flow Editor Modal -->
      <div v-if="showEditor" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
        <div class="w-full max-w-3xl p-6 bg-n-background rounded-lg shadow-xl max-h-[80vh] overflow-y-auto">
          <h3 class="text-lg font-medium text-n-slate-12 mb-4">
            {{ editingFlow ? $t('FLOW_BUILDER.EDIT_TITLE') : $t('FLOW_BUILDER.ADD_TITLE') }}
          </h3>
          <form @submit.prevent="saveFlow" class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">Flow Name</label>
              <input v-model="form.name" type="text" required
                class="w-full px-3 py-2 text-sm border rounded-lg border-n-slate-6 bg-n-background text-n-slate-12"
                placeholder="e.g. Welcome new users" />
            </div>
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">Description</label>
              <textarea v-model="form.description" rows="2"
                class="w-full px-3 py-2 text-sm border rounded-lg border-n-slate-6 bg-n-background text-n-slate-12"
                placeholder="What does this flow do?" />
            </div>

            <!-- Node list -->
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-2">Flow Nodes</label>
              <div class="space-y-2">
                <div v-for="(node, idx) in form.flow_data.nodes" :key="node.id"
                  class="flex items-center gap-2 p-3 bg-n-slate-2 rounded-lg">
                  <span class="text-xs font-mono text-n-slate-10">{{ idx + 1 }}</span>
                  <span class="px-2 py-0.5 text-xs rounded-full bg-n-brand-3 text-n-brand-11">
                    {{ node.type }}
                  </span>
                  <span class="text-sm text-n-slate-12 flex-1 truncate">
                    {{ JSON.stringify(node.data) }}
                  </span>
                  <button type="button" class="text-n-ruby-11 text-xs" @click="removeNode(node.id)">Remove</button>
                </div>
              </div>
              <div class="flex gap-2 mt-2">
                <button
                  v-for="nt in nodeTypes"
                  :key="nt.value"
                  type="button"
                  class="px-2 py-1 text-xs border rounded border-n-slate-6 text-n-slate-11 hover:bg-n-slate-3"
                  @click="addNode(nt.value)"
                >
                  + {{ nt.label }}
                </button>
              </div>
            </div>

            <div class="flex justify-end gap-2 pt-4">
              <NextButton ghost label="Cancel" @click="showEditor = false" />
              <NextButton solid blue type="submit" label="Save" />
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>
