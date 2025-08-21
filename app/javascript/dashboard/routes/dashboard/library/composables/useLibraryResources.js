import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';

export function useLibraryResources() {
  const store = useStore();
  const searchQuery = ref('');
  const currentPage = ref(1);
  const itemsPerPage = ref(10);

  // Load resources on mount
  onMounted(() => {
    store.dispatch('libraryResources/get');
  });

  // Getters from store
  const allResources = computed(
    () => store.getters['libraryResources/getLibraryResources']
  );

  const uiFlags = computed(() => store.getters['libraryResources/getUIFlags']);

  const isLoading = computed(() => uiFlags.value.isFetching);

  // Filter and paginate resources
  const filteredResources = computed(() => {
    if (!searchQuery.value) return allResources.value;

    const query = searchQuery.value.toLowerCase();
    return allResources.value.filter(
      resource =>
        resource.title.toLowerCase().includes(query) ||
        resource.description.toLowerCase().includes(query)
    );
  });

  const paginatedResources = computed(() => {
    const start = (currentPage.value - 1) * itemsPerPage.value;
    const end = start + itemsPerPage.value;
    return filteredResources.value.slice(start, end);
  });

  const totalItems = computed(() => filteredResources.value.length);
  const totalPages = computed(() =>
    Math.ceil(totalItems.value / itemsPerPage.value)
  );

  // Actions
  const searchResources = query => {
    searchQuery.value = query;
    currentPage.value = 1;
  };

  const updateCurrentPage = page => {
    currentPage.value = page;
  };

  const getResourceById = id => {
    return store.getters['libraryResources/getLibraryResource'](id);
  };

  const addResource = async resourceData => {
    try {
      await store.dispatch('libraryResources/create', resourceData);
      // Reset search and go to first page to show new resource
      searchQuery.value = '';
      currentPage.value = 1;
    } catch (error) {
      throw new Error(error);
    }
  };

  const updateResource = async (id, resourceData) => {
    try {
      return await store.dispatch('libraryResources/update', {
        id,
        resourceData,
      });
    } catch (error) {
      throw new Error(error);
    }
  };

  const deleteResource = async id => {
    try {
      await store.dispatch('libraryResources/delete', id);
      return true;
    } catch (error) {
      throw new Error(error);
    }
  };

  const fetchResource = async id => {
    try {
      return await store.dispatch('libraryResources/show', { id });
    } catch (error) {
      throw new Error(error);
    }
  };

  const uploadFile = async file => {
    try {
      return await store.dispatch('libraryResources/upload', file);
    } catch (error) {
      throw new Error(error);
    }
  };

  return {
    resources: paginatedResources,
    allResources,
    searchQuery,
    currentPage,
    totalItems,
    totalPages,
    isLoading,
    uiFlags,
    searchResources,
    updateCurrentPage,
    getResourceById,
    addResource,
    updateResource,
    deleteResource,
    fetchResource,
    uploadFile,
  };
}
