<script>
import { mapGetters, mapActions } from 'vuex';
import { useAlert } from 'dashboard/composables';
import FlowCanvas from './FlowCanvas.vue';
import NodeProperties from './NodeProperties.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  name: 'FlowBuilderEditor',
  components: {
    FlowCanvas,
    NodeProperties,
    NextButton,
  },
  props: {
    flow: {
      type: Object,
      default: null,
    },
    isNew: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['close', 'saved'],
  data() {
    return {
      form: {
        name: '',
        description: '',
        flow_data: { nodes: [], edges: [] },
        enabled: false,
      },
      selectedNodeId: null,
      draggedType: null,
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'conversationFlows/getUIFlags' }),
    selectedNode() {
      if (!this.selectedNodeId) return null;
      return this.form.flow_data.nodes.find(n => n.id === this.selectedNodeId);
    },
    nodeTypes() {
      return [
        { type: 'trigger', label: 'Trigger', icon: '⚡', color: '#1fe0b5', desc: 'Start flow on event' },
        { type: 'condition', label: 'Condition', icon: '🔀', color: '#ffc857', desc: 'Branch based on field' },
        { type: 'action', label: 'Action', icon: '⚡', color: '#1ba5ff', desc: 'Assign, set status, label' },
        { type: 'ai_reply', label: 'AI Reply', icon: '🤖', color: '#8b5cf6', desc: 'Generate AI response' },
        { type: 'send_message', label: 'Send Message', icon: '💬', color: '#10b981', desc: 'Send a fixed message' },
      ];
    },
  },
  mounted() {
    if (this.flow) {
      this.form = {
        name: this.flow.name,
        description: this.flow.description || '',
        flow_data: JSON.parse(JSON.stringify(this.flow.flow_data || { nodes: [], edges: [] })),
        enabled: this.flow.enabled,
      };
    }
  },
  methods: {
    ...mapActions('conversationFlows', ['createFlow', 'updateFlow']),
    addNode(type) {
      const id = `node_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`;
      const node = {
        id,
        type,
        data: this.defaultNodeData(type),
        position: { x: 200 + Math.random() * 200, y: 100 + Object.keys(this.form.flow_data.nodes).length * 120 },
      };
      this.form.flow_data.nodes.push(node);
      this.selectedNodeId = id;
    },
    defaultNodeData(type) {
      const defaults = {
        trigger: { event: 'conversation_created' },
        condition: { field: 'inbox_id', operator: 'equals', value: '' },
        action: { action: 'assign_agent', agent_id: '' },
        ai_reply: { prompt: 'Welcome message' },
        send_message: { content: '' },
      };
      return { ...defaults[type] };
    },
    deleteNode(nodeId) {
      this.form.flow_data.nodes = this.form.flow_data.nodes.filter(n => n.id !== nodeId);
      this.form.flow_data.edges = this.form.flow_data.edges.filter(
        e => e.source !== nodeId && e.target !== nodeId
      );
      if (this.selectedNodeId === nodeId) this.selectedNodeId = null;
    },
    onNodeMoved({ id, position }) {
      const node = this.form.flow_data.nodes.find(n => n.id === id);
      if (node) node.position = position;
    },
    onNodeSelected(id) {
      this.selectedNodeId = id;
    },
    onConnect({ source, target }) {
      const exists = this.form.flow_data.edges.some(
        e => e.source === source && e.target === target
      );
      if (!exists) {
        this.form.flow_data.edges.push({ source, target, label: '' });
      }
    },
    onEdgeDelete({ source, target }) {
      this.form.flow_data.edges = this.form.flow_data.edges.filter(
        e => !(e.source === source && e.target === target)
      );
    },
    updateNodeData(data) {
      const node = this.form.flow_data.nodes.find(n => n.id === this.selectedNodeId);
      if (node) node.data = { ...node.data, ...data };
    },
    async save() {
      try {
        if (this.isNew) {
          const created = await this.createFlow(this.form);
          this.$emit('saved', created);
        } else {
          const updated = await this.updateFlow({ id: this.flow.id, ...this.form });
          this.$emit('saved', updated);
        }
        useAlert('Flow saved');
      } catch (err) {
        useAlert(err.message || 'Failed to save');
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-full">
    <!-- Toolbar -->
    <div class="flex items-center justify-between px-4 py-2 border-b border-n-slate-6 bg-n-surface-1">
      <div class="flex items-center gap-3">
        <NextButton ghost icon="arrow-left" @click="$emit('close')" />
        <input
          v-model="form.name"
          class="text-sm font-medium bg-transparent border-none outline-none text-n-slate-12 w-64"
          placeholder="Flow name..."
        />
      </div>
      <div class="flex items-center gap-2">
        <label class="flex items-center gap-2 text-xs text-n-slate-11">
          <input type="checkbox" v-model="form.enabled" class="accent-n-brand" />
          Enabled
        </label>
        <NextButton solid blue label="Save" @click="save" />
      </div>
    </div>

    <div class="flex flex-1 overflow-hidden">
      <!-- Node palette -->
      <div class="w-52 border-r border-n-slate-6 bg-n-surface-1 p-3 overflow-y-auto">
        <div class="text-xs font-medium text-n-slate-10 uppercase tracking-wide mb-2">Add Nodes</div>
        <div class="space-y-2">
          <button
            v-for="nt in nodeTypes"
            :key="nt.type"
            class="w-full flex items-center gap-2 p-2 rounded-lg border border-n-slate-6 hover:border-n-brand hover:bg-n-surface-2 text-left transition-colors"
            @click="addNode(nt.type)"
          >
            <span class="text-lg">{{ nt.icon }}</span>
            <div>
              <div class="text-sm font-medium text-n-slate-12">{{ nt.label }}</div>
              <div class="text-[10px] text-n-slate-10">{{ nt.desc }}</div>
            </div>
          </button>
        </div>

        <!-- Description -->
        <div class="mt-4">
          <div class="text-xs font-medium text-n-slate-10 uppercase tracking-wide mb-1">Description</div>
          <textarea
            v-model="form.description"
            rows="3"
            class="w-full px-2 py-1.5 text-xs border rounded border-n-slate-6 bg-n-background text-n-slate-12 resize-none"
            placeholder="What does this flow do?"
          />
        </div>
      </div>

      <!-- Canvas -->
      <FlowCanvas
        :nodes="form.flow_data.nodes"
        :edges="form.flow_data.edges"
        :selected-node-id="selectedNodeId"
        @node-moved="onNodeMoved"
        @node-selected="onNodeSelected"
        @connect="onConnect"
        @edge-delete="onEdgeDelete"
      />

      <!-- Properties panel -->
      <NodeProperties
        v-if="selectedNode"
        :node="selectedNode"
        @update="updateNodeData"
        @delete="deleteNode(selectedNode.id)"
      />
    </div>
  </div>
</template>
