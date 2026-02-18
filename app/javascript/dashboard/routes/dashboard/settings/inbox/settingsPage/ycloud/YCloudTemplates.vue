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
      templates: [],
      isLoading: false,
      showCreateModal: false,
      showEditModal: false,
      editingTemplate: null,
      newTemplate: { name: '', language: 'en_US', category: 'UTILITY', components: [] },
      newBodyText: '',
      searchQuery: '',
    };
  },
  computed: {
    filteredTemplates() {
      if (!this.searchQuery) return this.templates;
      const q = this.searchQuery.toLowerCase();
      return this.templates.filter(
        t => t.name.toLowerCase().includes(q) || t.language.toLowerCase().includes(q)
      );
    },
    categoryOptions() {
      return ['AUTHENTICATION', 'UTILITY', 'MARKETING'];
    },
  },
  mounted() {
    this.fetchTemplates();
  },
  methods: {
    async fetchTemplates() {
      this.isLoading = true;
      try {
        const res = await YCloudAPI.listTemplates(this.inbox.id);
        this.templates = res.data.items || res.data || [];
      } catch {
        useAlert(this.$t('YCLOUD.TEMPLATES.FETCH_ERROR'));
      }
      this.isLoading = false;
    },
    async createTemplate() {
      try {
        const components = [];
        if (this.newBodyText) {
          components.push({ type: 'BODY', text: this.newBodyText });
        }
        await YCloudAPI.createTemplate(this.inbox.id, {
          ...this.newTemplate,
          components,
        });
        useAlert(this.$t('YCLOUD.TEMPLATES.CREATE_SUCCESS'));
        this.showCreateModal = false;
        this.resetNewTemplate();
        this.fetchTemplates();
      } catch (e) {
        useAlert(this.$t('YCLOUD.TEMPLATES.CREATE_ERROR'));
      }
    },
    async deleteTemplate(template) {
      if (!window.confirm(this.$t('YCLOUD.TEMPLATES.DELETE_CONFIRM', { name: template.name }))) return;
      try {
        await YCloudAPI.deleteTemplate(this.inbox.id, template.name, template.language);
        useAlert(this.$t('YCLOUD.TEMPLATES.DELETE_SUCCESS'));
        this.fetchTemplates();
      } catch {
        useAlert(this.$t('YCLOUD.TEMPLATES.DELETE_ERROR'));
      }
    },
    openEditModal(template) {
      this.editingTemplate = { ...template };
      this.showEditModal = true;
    },
    async saveEditTemplate() {
      try {
        await YCloudAPI.updateTemplate(
          this.inbox.id,
          this.editingTemplate.name,
          this.editingTemplate.language,
          { category: this.editingTemplate.category, components: this.editingTemplate.components }
        );
        useAlert(this.$t('YCLOUD.TEMPLATES.UPDATE_SUCCESS'));
        this.showEditModal = false;
        this.fetchTemplates();
      } catch {
        useAlert(this.$t('YCLOUD.TEMPLATES.UPDATE_ERROR'));
      }
    },
    resetNewTemplate() {
      this.newTemplate = { name: '', language: 'en_US', category: 'UTILITY', components: [] };
      this.newBodyText = '';
    },
    statusColor(status) {
      const colors = { approved: 'text-green-600', pending: 'text-yellow-600', rejected: 'text-red-600' };
      return colors[status?.toLowerCase()] || 'text-n-slate-11';
    },
    getBodyText(components) {
      const body = (components || []).find(c => c.type === 'BODY' || c.type === 'body');
      return body?.text || '';
    },
  },
};
</script>

<template>
  <div class="py-4">
    <SettingsSection
      :title="$t('YCLOUD.TEMPLATES.TITLE')"
      :sub-title="$t('YCLOUD.TEMPLATES.DESC')"
      :show-border="false"
    >
      <div class="flex items-center gap-3 mb-4">
        <input
          v-model="searchQuery"
          type="text"
          :placeholder="$t('YCLOUD.TEMPLATES.SEARCH')"
          class="flex-1"
        />
        <NextButton
          :label="$t('YCLOUD.TEMPLATES.CREATE')"
          icon="i-lucide-plus"
          @click="showCreateModal = true"
        />
      </div>

      <div v-if="isLoading" class="text-center py-8">
        <span class="spinner" />
      </div>

      <div v-else-if="filteredTemplates.length === 0" class="text-center py-8 text-n-slate-11">
        {{ $t('YCLOUD.TEMPLATES.EMPTY') }}
      </div>

      <table v-else class="min-w-full">
        <thead>
          <tr class="border-b border-n-weak">
            <th class="text-left py-2 px-3 text-sm font-medium">{{ $t('YCLOUD.TEMPLATES.NAME') }}</th>
            <th class="text-left py-2 px-3 text-sm font-medium">{{ $t('YCLOUD.TEMPLATES.LANGUAGE') }}</th>
            <th class="text-left py-2 px-3 text-sm font-medium">{{ $t('YCLOUD.TEMPLATES.CATEGORY') }}</th>
            <th class="text-left py-2 px-3 text-sm font-medium">{{ $t('YCLOUD.TEMPLATES.STATUS') }}</th>
            <th class="text-left py-2 px-3 text-sm font-medium">{{ $t('YCLOUD.TEMPLATES.BODY') }}</th>
            <th class="text-right py-2 px-3 text-sm font-medium">{{ $t('YCLOUD.TEMPLATES.ACTIONS') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="tpl in filteredTemplates" :key="`${tpl.name}-${tpl.language}`" class="border-b border-n-weak/50 hover:bg-n-slate-1">
            <td class="py-2 px-3 font-medium text-sm">{{ tpl.name }}</td>
            <td class="py-2 px-3 text-sm">{{ tpl.language }}</td>
            <td class="py-2 px-3 text-sm">{{ tpl.category }}</td>
            <td class="py-2 px-3 text-sm">
              <span :class="statusColor(tpl.status)" class="font-medium">{{ tpl.status }}</span>
            </td>
            <td class="py-2 px-3 text-sm text-n-slate-11 max-w-xs truncate">{{ getBodyText(tpl.components) }}</td>
            <td class="py-2 px-3 text-right">
              <button class="text-n-blue-text text-sm mr-2 hover:underline" @click="openEditModal(tpl)">
                {{ $t('YCLOUD.COMMON.EDIT') }}
              </button>
              <button class="text-red-600 text-sm hover:underline" @click="deleteTemplate(tpl)">
                {{ $t('YCLOUD.COMMON.DELETE') }}
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </SettingsSection>

    <!-- Create Modal -->
    <div v-if="showCreateModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div class="bg-white rounded-xl p-6 w-full max-w-lg shadow-xl">
        <h3 class="text-lg font-semibold mb-4">{{ $t('YCLOUD.TEMPLATES.CREATE') }}</h3>
        <label class="block mb-3">
          {{ $t('YCLOUD.TEMPLATES.NAME') }}
          <input v-model="newTemplate.name" type="text" class="mt-1" placeholder="hello_world" />
        </label>
        <label class="block mb-3">
          {{ $t('YCLOUD.TEMPLATES.LANGUAGE') }}
          <input v-model="newTemplate.language" type="text" class="mt-1" placeholder="en_US" />
        </label>
        <label class="block mb-3">
          {{ $t('YCLOUD.TEMPLATES.CATEGORY') }}
          <select v-model="newTemplate.category" class="mt-1">
            <option v-for="cat in categoryOptions" :key="cat" :value="cat">{{ cat }}</option>
          </select>
        </label>
        <label class="block mb-3">
          {{ $t('YCLOUD.TEMPLATES.BODY') }}
          <textarea v-model="newBodyText" rows="4" class="mt-1" placeholder="Hello {{1}}, your order is ready!" />
        </label>
        <div class="flex justify-end gap-2 mt-4">
          <NextButton :label="$t('YCLOUD.COMMON.CANCEL')" variant="ghost" @click="showCreateModal = false; resetNewTemplate()" />
          <NextButton :label="$t('YCLOUD.COMMON.SAVE')" @click="createTemplate" />
        </div>
      </div>
    </div>

    <!-- Edit Modal -->
    <div v-if="showEditModal && editingTemplate" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div class="bg-white rounded-xl p-6 w-full max-w-lg shadow-xl">
        <h3 class="text-lg font-semibold mb-4">{{ $t('YCLOUD.TEMPLATES.EDIT_TITLE', { name: editingTemplate.name }) }}</h3>
        <label class="block mb-3">
          {{ $t('YCLOUD.TEMPLATES.CATEGORY') }}
          <select v-model="editingTemplate.category" class="mt-1">
            <option v-for="cat in categoryOptions" :key="cat" :value="cat">{{ cat }}</option>
          </select>
        </label>
        <div class="flex justify-end gap-2 mt-4">
          <NextButton :label="$t('YCLOUD.COMMON.CANCEL')" variant="ghost" @click="showEditModal = false" />
          <NextButton :label="$t('YCLOUD.COMMON.SAVE')" @click="saveEditTemplate" />
        </div>
      </div>
    </div>
  </div>
</template>
