<script>
import { mapGetters, mapActions } from 'vuex';
import { useAlert } from 'dashboard/composables';
import PageHeader from '../SettingsSubPageHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  name: 'KnowledgeBase',
  components: {
    PageHeader,
    NextButton,
  },
  data() {
    return {
      showAddForm: false,
      editingEntry: null,
      form: {
        name: '',
        content: '',
        category: '',
        enabled: true,
      },
    };
  },
  computed: {
    ...mapGetters({
      entries: 'knowledgeBase/getEntries',
      uiFlags: 'knowledgeBase/getUIFlags',
    }),
  },
  mounted() {
    this.fetchEntries();
  },
  methods: {
    ...mapActions('knowledgeBase', [
      'fetchEntries',
      'createEntry',
      'updateEntry',
      'deleteEntry',
    ]),
    resetForm() {
      this.form = { name: '', content: '', category: '', enabled: true };
      this.editingEntry = null;
    },
    openAddForm() {
      this.resetForm();
      this.showAddForm = true;
    },
    editEntry(entry) {
      this.form = {
        name: entry.name,
        content: entry.content,
        category: entry.category || '',
        enabled: entry.enabled,
      };
      this.editingEntry = entry;
      this.showAddForm = true;
    },
    async handleSubmit() {
      try {
        if (this.editingEntry) {
          await this.updateEntry({ id: this.editingEntry.id, ...this.form });
          useAlert(this.$t('KNOWLEDGE_BASE.UPDATE.SUCCESS'));
        } else {
          await this.createEntry(this.form);
          useAlert(this.$t('KNOWLEDGE_BASE.CREATE.SUCCESS'));
        }
        this.showAddForm = false;
        this.resetForm();
      } catch (error) {
        useAlert(error.message || this.$t('KNOWLEDGE_BASE.ERROR'));
      }
    },
    async handleDelete(entry) {
      try {
        await this.deleteEntry(entry.id);
        useAlert(this.$t('KNOWLEDGE_BASE.DELETE.SUCCESS'));
      } catch (error) {
        useAlert(error.message || this.$t('KNOWLEDGE_BASE.ERROR'));
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-full overflow-auto">
    <PageHeader
      :header-title="$t('KNOWLEDGE_BASE.TITLE')"
      :header-content="$t('KNOWLEDGE_BASE.DESC')"
    />
    <div class="flex-1 px-6 py-4">
      <NextButton
        class="mb-4"
        solid
        blue
        :label="$t('KNOWLEDGE_BASE.ADD_BUTTON')"
        @click="openAddForm"
      />

      <div class="space-y-3">
        <div
          v-for="entry in entries"
          :key="entry.id"
          class="flex items-center justify-between p-4 border rounded-lg border-n-slate-6"
        >
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2">
              <span class="font-medium text-n-slate-12">{{ entry.name }}</span>
              <span
                v-if="entry.category"
                class="px-2 py-0.5 text-xs rounded-full bg-n-slate-4 text-n-slate-11"
              >
                {{ entry.category }}
              </span>
              <span
                v-if="!entry.enabled"
                class="px-2 py-0.5 text-xs rounded-full bg-n-ruby-3 text-n-ruby-11"
              >
                {{ $t('KNOWLEDGE_BASE.DISABLED') }}
              </span>
            </div>
            <p class="text-sm text-n-slate-11 mt-1 truncate">
              {{ entry.content }}
            </p>
          </div>
          <div class="flex items-center gap-2 ml-4">
            <NextButton
              ghost
              :label="$t('KNOWLEDGE_BASE.EDIT')"
              @click="editEntry(entry)"
            />
            <NextButton
              ghost
              red
              :label="$t('KNOWLEDGE_BASE.DELETE.BUTTON')"
              @click="handleDelete(entry)"
            />
          </div>
        </div>
      </div>

      <div v-if="showAddForm" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
        <div class="w-full max-w-lg p-6 bg-n-background rounded-lg shadow-xl">
          <h3 class="text-lg font-medium text-n-slate-12 mb-4">
            {{ editingEntry ? $t('KNOWLEDGE_BASE.EDIT_TITLE') : $t('KNOWLEDGE_BASE.ADD_TITLE') }}
          </h3>
          <form @submit.prevent="handleSubmit" class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">{{ $t('KNOWLEDGE_BASE.FORM.NAME') }}</label>
              <input
                v-model="form.name"
                type="text"
                required
                class="w-full px-3 py-2 text-sm border rounded-lg border-n-slate-6 bg-n-background text-n-slate-12"
                :placeholder="$t('KNOWLEDGE_BASE.FORM.NAME_PLACEHOLDER')"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">{{ $t('KNOWLEDGE_BASE.FORM.CONTENT') }}</label>
              <textarea
                v-model="form.content"
                rows="6"
                required
                class="w-full px-3 py-2 text-sm border rounded-lg border-n-slate-6 bg-n-background text-n-slate-12"
                :placeholder="$t('KNOWLEDGE_BASE.FORM.CONTENT_PLACEHOLDER')"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">{{ $t('KNOWLEDGE_BASE.FORM.CATEGORY') }}</label>
              <input
                v-model="form.category"
                type="text"
                class="w-full px-3 py-2 text-sm border rounded-lg border-n-slate-6 bg-n-background text-n-slate-12"
                :placeholder="$t('KNOWLEDGE_BASE.FORM.CATEGORY_PLACEHOLDER')"
              />
            </div>
            <div class="flex items-center gap-2">
              <input v-model="form.enabled" type="checkbox" class="rounded border-n-slate-6" />
              <label class="text-sm text-n-slate-11">{{ $t('KNOWLEDGE_BASE.FORM.ENABLED') }}</label>
            </div>
            <div class="flex justify-end gap-2 pt-4">
              <NextButton ghost :label="$t('KNOWLEDGE_BASE.FORM.CANCEL')" @click="showAddForm = false" />
              <NextButton
                solid blue type="submit"
                :is-loading="uiFlags.isCreating || uiFlags.isUpdating"
                :label="$t('KNOWLEDGE_BASE.FORM.SAVE')"
              />
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>
