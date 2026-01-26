import { ref, computed } from 'vue';
import notionAPI from '../api/notion';

export function useNotionDatabase() {
  const databases = ref([]);
  const databaseSchema = ref(null);
  const notionRecordsPreview = ref([]);
  const loading = ref(false);
  const loadingPreview = ref(false);
  const error = ref(null);

  const fetchDatabases = async () => {
    loading.value = true;
    error.value = null;
    try {
      const response = await notionAPI.listDatabases();
      databases.value = response.data.databases || [];
      return databases.value;
    } catch (err) {
      error.value = err.message;
      console.error('Failed to fetch Notion databases:', err);
      return [];
    } finally {
      loading.value = false;
    }
  };

  const fetchDatabaseSchema = async databaseId => {
    if (!databaseId) {
      databaseSchema.value = null;
      return null;
    }

    loading.value = true;
    error.value = null;
    try {
      const response = await notionAPI.getDatabaseSchema(databaseId);
      databaseSchema.value = response.data;
      return response.data;
    } catch (err) {
      error.value = err.message;
      console.error('Failed to fetch database schema:', err);
      databaseSchema.value = null;
      return null;
    } finally {
      loading.value = false;
    }
  };

  const queryDatabase = async (databaseId, filters = {}) => {
    loadingPreview.value = true;
    error.value = null;
    try {
      const response = await notionAPI.queryDatabase(databaseId, filters);
      notionRecordsPreview.value = response.data.records || [];
      return response.data.records || [];
    } catch (err) {
      error.value = err.message;
      console.error('Failed to query database:', err);
      notionRecordsPreview.value = [];
      return [];
    } finally {
      loadingPreview.value = false;
    }
  };

  // Computed properties for different field types
  const textFields = computed(() => {
    if (!databaseSchema.value?.properties) return [];
    return databaseSchema.value.properties.filter(p =>
      ['title', 'rich_text'].includes(p.type)
    );
  });

  const dateFields = computed(() => {
    if (!databaseSchema.value?.properties) return [];
    return databaseSchema.value.properties.filter(p => p.type === 'date');
  });

  const phoneNumberFields = computed(() => {
    if (!databaseSchema.value?.properties) return [];
    return databaseSchema.value.properties.filter(p =>
      ['phone_number', 'rich_text', 'title'].includes(p.type)
    );
  });

  const emailFields = computed(() => {
    if (!databaseSchema.value?.properties) return [];
    return databaseSchema.value.properties.filter(p =>
      ['email', 'rich_text', 'title'].includes(p.type)
    );
  });

  const selectFields = computed(() => {
    if (!databaseSchema.value?.properties) return [];
    return databaseSchema.value.properties.filter(p =>
      ['select', 'multi_select'].includes(p.type)
    );
  });

  const numberFields = computed(() => {
    if (!databaseSchema.value?.properties) return [];
    return databaseSchema.value.properties.filter(p => p.type === 'number');
  });

  const allFields = computed(() => {
    if (!databaseSchema.value?.properties) return [];
    return databaseSchema.value.properties;
  });

  return {
    databases,
    databaseSchema,
    notionRecordsPreview,
    loading,
    loadingPreview,
    error,
    textFields,
    dateFields,
    phoneNumberFields,
    emailFields,
    selectFields,
    numberFields,
    allFields,
    fetchDatabases,
    fetchDatabaseSchema,
    queryDatabase,
  };
}
