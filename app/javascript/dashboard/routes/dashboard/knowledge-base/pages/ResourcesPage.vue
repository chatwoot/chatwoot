<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';

import KnowledgeBaseLayout from 'dashboard/components-next/KnowledgeBase/KnowledgeBaseLayout.vue';
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import ProductSearchSelect from 'dashboard/components-next/KnowledgeBase/ProductSearchSelect.vue';
import ResourceDetailDrawer from 'dashboard/components-next/KnowledgeBase/ResourceDetailDrawer.vue';
import TreeNode from 'dashboard/components-next/KnowledgeBase/TreeNode.vue';

const { t } = useI18n();
const store = useStore();

// UI State
const showUploadModal = ref(false);
const showEditModal = ref(false);
const showDeleteModal = ref(false);
const editingResource = ref(null);
const resourceToDelete = ref(null);

// Drawer state
const selectedResource = ref(null);

// View mode: 'list' (S3-like navigation) or 'tree' (2D tree view)
const viewMode = ref('list');

// Folder navigation state
const currentFolder = ref('/');
const showCreateFolderModal = ref(false);
const newFolderName = ref('');
const isCreatingFolder = ref(false);
const showMoveModal = ref(false);
const resourceToMove = ref(null);
const moveTargetFolder = ref('/');

// Tree view selection state
const selectedTreeItem = ref(null); // { type: 'file' | 'folder', data: object }
const showDeleteFolderModal = ref(false);
const folderToDelete = ref(null);
const isDeletingFolder = ref(false);
const parentFolderForNewFolder = ref('/'); // Used when creating folder from tree view

// Force delete folder state (when folder is not empty)
const folderDeleteRequiresConfirmation = ref(false);
const folderDeleteContents = ref({ resources: 0, subfolders: 0 });
const folderDeleteConfirmText = ref('');
const expectedDeletePhrase = computed(() => `delete ${folderToDelete.value?.name || ''}`);
const isDeletePhraseCorrect = computed(() =>
  folderDeleteConfirmText.value.toLowerCase().trim() === expectedDeletePhrase.value.toLowerCase()
);

// List view selection state
const selectedListFolder = ref(null); // Selected folder in list view

// Move modal navigation state
const moveBrowserPath = ref('/');

// Accordion state for associations section
const uploadAccordionOpen = ref(false);
const uploadProductsAccordionOpen = ref(false);
const editAccordionOpen = ref(false);
const editProductsAccordionOpen = ref(false);

// Form data - updated for multi-select
const uploadForm = ref({
  file: null,
  name: '',
  description: '',
  product_catalog_ids: [],
});
const editForm = ref({ name: '', description: '', product_catalog_ids: [] });

// Search and pagination
const searchQuery = ref('');
const isSearching = ref(false);
const searchDebounceTimer = ref(null);

// File input ref
const fileInputRef = ref(null);
const selectedFileName = ref('');
const selectedFileSize = ref(0);
const fileSizeError = ref(false);

// Validation limits (matching backend)
const LIMITS = {
  RESOURCE_NAME_MAX: 255,
  RESOURCE_DESCRIPTION_MAX: 1000,
  FOLDER_NAME_MAX: 100,
  MAX_FILE_SIZE: 200 * 1024 * 1024, // 200MB in bytes
};

// Validation helpers
const isResourceNameValid = computed(() => {
  const name = uploadForm.value.name || '';
  return name.length <= LIMITS.RESOURCE_NAME_MAX && !containsDangerousPatterns(name);
});

const isResourceDescriptionValid = computed(() => {
  const desc = uploadForm.value.description || '';
  return desc.length <= LIMITS.RESOURCE_DESCRIPTION_MAX && !containsDangerousPatterns(desc);
});

const isEditNameValid = computed(() => {
  const name = editForm.value.name || '';
  return name.length <= LIMITS.RESOURCE_NAME_MAX && !containsDangerousPatterns(name);
});

const isEditDescriptionValid = computed(() => {
  const desc = editForm.value.description || '';
  return desc.length <= LIMITS.RESOURCE_DESCRIPTION_MAX && !containsDangerousPatterns(desc);
});

const isFolderNameValid = computed(() => {
  const name = newFolderName.value || '';
  if (!name.trim()) return true; // Empty is handled by required validation
  if (name.length > LIMITS.FOLDER_NAME_MAX) return false;
  if (name.includes('..') || name.includes('/')) return false;
  if (name.startsWith('.')) return false;
  if (/[<>:"|?*\x00-\x1f\\]/.test(name)) return false;
  return true;
});

const containsDangerousPatterns = (text) => {
  if (!text) return false;
  const patterns = ['..', '<script', 'javascript:'];
  return patterns.some(p => text.toLowerCase().includes(p.toLowerCase()));
};

// Getters
const resources = computed(() => store.getters['kbResources/getKbResources']);
const folders = computed(() => store.getters['kbResources/getFolders']);
const meta = computed(() => store.getters['kbResources/getMeta']);
const uiFlags = computed(() => store.getters['kbResources/getUIFlags']);
const productCatalogs = computed(() => store.getters['productCatalogs/getProductCatalogs']);
const treeData = computed(() => store.getters['kbResources/getTree']);

const isLoading = computed(() => uiFlags.value.isFetching);
const isLoadingTree = computed(() => uiFlags.value.isFetchingTree);
const isSaving = computed(() => uiFlags.value.isCreating || uiFlags.value.isUpdating);
const isDeleting = computed(() => uiFlags.value.isDeleting);
const isMoving = computed(() => uiFlags.value.isMoving);

const isEmpty = computed(() => !isLoading.value && resources.value.length === 0 && folders.value.length === 0 && !searchQuery.value && currentFolder.value === '/');

// Tree view state
const expandedFolders = ref(new Set(['/']));

// Build hierarchical tree structure
const treeStructure = computed(() => {
  if (!treeData.value.folders.length && !treeData.value.resources.length) {
    return { name: 'Root', path: '/', children: [], files: [] };
  }

  // Create a map of folders by path
  const folderMap = new Map();
  folderMap.set('/', { name: 'Root', path: '/', children: [], files: [] });

  // Add all folders to the map
  treeData.value.folders.forEach(folder => {
    folderMap.set(folder.path, {
      ...folder,
      children: [],
      files: [],
    });
  });

  // Build parent-child relationships
  treeData.value.folders.forEach(folder => {
    const parent = folderMap.get(folder.parent_path);
    if (parent) {
      parent.children.push(folderMap.get(folder.path));
    }
  });

  // Add resources to their respective folders
  treeData.value.resources.forEach(resource => {
    const folder = folderMap.get(resource.folder_path) || folderMap.get('/');
    if (folder) {
      folder.files.push(resource);
    }
  });

  // Sort children and files
  const sortNode = (node) => {
    node.children.sort((a, b) => a.name.localeCompare(b.name));
    node.files.sort((a, b) => a.name.localeCompare(b.name));
    node.children.forEach(sortNode);
    return node;
  };

  return sortNode(folderMap.get('/'));
});

// Toggle folder expansion in tree view
const toggleFolderExpand = (path) => {
  if (expandedFolders.value.has(path)) {
    expandedFolders.value.delete(path);
  } else {
    expandedFolders.value.add(path);
  }
  expandedFolders.value = new Set(expandedFolders.value); // Trigger reactivity
};

const isFolderExpanded = (path) => expandedFolders.value.has(path);

// Expand all folders
const expandAllFolders = () => {
  const allPaths = new Set(['/']);
  treeData.value.folders.forEach(f => allPaths.add(f.path));
  expandedFolders.value = allPaths;
};

// Collapse all folders
const collapseAllFolders = () => {
  expandedFolders.value = new Set(['/']);
};

// Breadcrumb parts for current path
const breadcrumbs = computed(() => {
  if (currentFolder.value === '/') return [{ name: 'Root', path: '/' }];
  const parts = currentFolder.value.split('/').filter(Boolean);
  let path = '';
  return [
    { name: 'Root', path: '/' },
    ...parts.map(part => {
      path += '/' + part;
      return { name: part, path };
    }),
  ];
});

// All unique folder paths for move modal
const allFolderPaths = computed(() => {
  const paths = new Set(['/']);
  // Get all unique folder paths from resources we've seen
  resources.value.forEach(r => {
    if (r.folder_path) paths.add(r.folder_path);
  });
  // Folders are now objects with { name, path }
  folders.value.forEach(f => {
    if (f.path) paths.add(f.path);
  });
  return Array.from(paths).sort();
});

// Folders visible in move modal browser (subfolders of current moveBrowserPath)
const moveBrowserFolders = computed(() => {
  // Get all folders from tree data if available, otherwise use regular folders
  const allFolders = treeData.value.folders.length > 0
    ? treeData.value.folders
    : folders.value.map(f => ({ name: f.name, path: f.path, parent_path: f.parent_path || '/' }));

  return allFolders
    .filter(f => f.parent_path === moveBrowserPath.value)
    .sort((a, b) => a.name.localeCompare(b.name));
});

// Storage info
const storageUsed = computed(() => meta.value?.storage_used || 0);
const storageLimit = computed(() => meta.value?.storage_limit || 2 * 1024 * 1024 * 1024);
const storagePercentage = computed(() => Math.round((storageUsed.value / storageLimit.value) * 100));


// Format file size
const formatFileSize = (bytes) => {
  if (!bytes) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  let unitIndex = 0;
  let size = bytes;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  return `${size.toFixed(1)} ${units[unitIndex]}`;
};

// Get file type icon
const getFileIcon = (contentType) => {
  if (!contentType) return 'i-lucide-file';
  if (contentType.includes('pdf')) return 'i-lucide-file-text';
  if (contentType.includes('word') || contentType.includes('document')) return 'i-lucide-file-text';
  if (contentType.includes('excel') || contentType.includes('spreadsheet')) return 'i-lucide-file-spreadsheet';
  if (contentType.includes('csv')) return 'i-lucide-file-spreadsheet';
  if (contentType.includes('json')) return 'i-lucide-file-json';
  if (contentType.includes('text')) return 'i-lucide-file-text';
  if (contentType.includes('image')) return 'i-lucide-image';
  if (contentType.includes('audio')) return 'i-lucide-music';
  if (contentType.includes('video')) return 'i-lucide-video';
  return 'i-lucide-file';
};

// Pagination
const visiblePages = computed(() => {
  const current = meta.value?.current_page || 1;
  const total = meta.value?.total_pages || 1;
  const pages = [];

  if (total <= 7) {
    for (let i = 1; i <= total; i++) pages.push(i);
  } else {
    pages.push(1);
    if (current <= 3) {
      for (let i = 2; i <= 5; i++) pages.push(i);
      pages.push('ellipsis1');
      pages.push(total);
    } else if (current >= total - 2) {
      pages.push('ellipsis1');
      for (let i = total - 4; i <= total; i++) pages.push(i);
    } else {
      pages.push('ellipsis1');
      pages.push(current - 1);
      pages.push(current);
      pages.push(current + 1);
      pages.push('ellipsis2');
      pages.push(total);
    }
  }
  return pages;
});

// Methods
const fetchData = async () => {
  await Promise.all([
    store.dispatch('kbResources/get', { page: 1, per_page: 50, folder_path: currentFolder.value }),
    store.dispatch('productCatalogs/get', { per_page: 1000 }),
  ]);
};

const fetchTreeData = async () => {
  await store.dispatch('kbResources/fetchTree');
};

// Watch for view mode changes and sync state between views
watch(viewMode, async (newMode, oldMode) => {
  if (newMode === 'tree') {
    await fetchTreeData();
    // Expand folders based on current list view path
    if (currentFolder.value && currentFolder.value !== '/') {
      // Expand all parent folders leading to the current path
      const parts = currentFolder.value.split('/').filter(Boolean);
      let path = '';
      expandedFolders.value.add('/');
      parts.forEach(part => {
        path += '/' + part;
        expandedFolders.value.add(path);
      });
      expandedFolders.value = new Set(expandedFolders.value); // Trigger reactivity
    }
  } else if (newMode === 'list' && oldMode === 'tree') {
    // When switching from tree to list, navigate to selected item's location
    if (selectedTreeItem.value) {
      const targetPath = selectedTreeItem.value.type === 'folder'
        ? selectedTreeItem.value.data.path
        : selectedTreeItem.value.data.folder_path;
      if (targetPath && targetPath !== currentFolder.value) {
        await navigateToFolder(targetPath);
      }
      clearTreeSelection();
    }
  }
});

const refreshData = async () => {
  const currentPage = meta.value?.current_page || 1;
  await store.dispatch('kbResources/get', {
    page: currentPage,
    per_page: 50,
    folder_path: currentFolder.value,
    q: searchQuery.value || undefined,
  });
};

// Navigate to folder
const navigateToFolder = async (path) => {
  currentFolder.value = path;
  searchQuery.value = '';
  selectedListFolder.value = null; // Clear selection when navigating
  await store.dispatch('kbResources/get', { page: 1, per_page: 50, folder_path: path });
};

// Create folder
const openCreateFolderModal = () => {
  newFolderName.value = '';
  parentFolderForNewFolder.value = currentFolder.value;
  showCreateFolderModal.value = true;
};

const createFolder = async () => {
  await createFolderFromTree();
};

// Move resource
const openMoveModal = (resource) => {
  resourceToMove.value = resource;
  moveTargetFolder.value = resource.folder_path || '/';
  moveBrowserPath.value = resource.folder_path || '/';
  showMoveModal.value = true;
  selectedResource.value = null;
  // Fetch tree data to have all folders available
  if (!treeData.value.folders.length) {
    fetchTreeData();
  }
};

// Move browser navigation
const moveBrowserNavigateTo = (path) => {
  moveBrowserPath.value = path;
  moveTargetFolder.value = path;
};

const moveBrowserGoUp = () => {
  if (moveBrowserPath.value === '/') return;
  const parts = moveBrowserPath.value.split('/').filter(Boolean);
  parts.pop();
  const parentPath = parts.length === 0 ? '/' : '/' + parts.join('/');
  moveBrowserNavigateTo(parentPath);
};

// List view folder selection
const selectListFolder = (folder) => {
  selectedListFolder.value = folder;
};

const clearListFolderSelection = () => {
  selectedListFolder.value = null;
};

// Handle list folder actions
const handleListFolderAction = (action) => {
  if (!selectedListFolder.value) return;
  const folder = selectedListFolder.value;

  switch (action) {
    case 'open':
      navigateToFolder(folder.path);
      clearListFolderSelection();
      break;
    case 'newSubfolder':
      parentFolderForNewFolder.value = folder.path;
      newFolderName.value = '';
      showCreateFolderModal.value = true;
      clearListFolderSelection();
      break;
    case 'delete':
      confirmDeleteFolder(folder);
      clearListFolderSelection();
      break;
  }
};

const moveResource = async () => {
  if (!resourceToMove.value || isMoving.value) return;

  try {
    await store.dispatch('kbResources/move', {
      id: resourceToMove.value.id,
      folderPath: moveTargetFolder.value,
    });
    useAlert(t('KNOWLEDGE_BASE.RESOURCES.MOVE.SUCCESS'));
    showMoveModal.value = false;
    await refreshData();
    // Also refresh tree if in tree view
    if (viewMode.value === 'tree') {
      await fetchTreeData();
    }
  } catch (error) {
    useAlert(t('KNOWLEDGE_BASE.RESOURCES.MOVE.ERROR'));
  }
};

// Search
const executeSearch = async (query) => {
  if (isSearching.value) return;
  isSearching.value = true;
  try {
    await store.dispatch('kbResources/get', {
      page: 1,
      per_page: 50,
      folder_path: currentFolder.value,
      q: query || undefined,
    });
  } finally {
    isSearching.value = false;
  }
};

const performSearch = (query) => {
  if (searchDebounceTimer.value) clearTimeout(searchDebounceTimer.value);
  searchDebounceTimer.value = setTimeout(() => {
    executeSearch(query);
    searchDebounceTimer.value = null;
  }, 500);
};

const handleSearchEnter = () => {
  if (searchDebounceTimer.value) {
    clearTimeout(searchDebounceTimer.value);
    searchDebounceTimer.value = null;
  }
  executeSearch(searchQuery.value);
};

watch(searchQuery, (newQuery) => performSearch(newQuery));

// Pagination
const handlePageChange = async (page) => {
  const totalPages = meta.value?.total_pages || 1;
  const currentPage = meta.value?.current_page || 1;
  if (page < 1 || page > totalPages || page === currentPage) return;
  await store.dispatch('kbResources/get', {
    page,
    per_page: 50,
    folder_path: currentFolder.value,
    q: searchQuery.value || undefined,
  });
};

// Open resource detail drawer
const openResourceDetail = (resource) => {
  selectedResource.value = resource;
};

const closeResourceDetail = () => {
  selectedResource.value = null;
};

// Upload modal
const openUploadModal = () => {
  uploadForm.value = { file: null, name: '', description: '', product_catalog_ids: [] };
  selectedFileName.value = '';
  selectedFileSize.value = 0;
  fileSizeError.value = false;
  uploadAccordionOpen.value = false;
  uploadProductsAccordionOpen.value = false;
  showUploadModal.value = true;
};

const handleFileSelect = (event) => {
  const file = event.target.files[0];
  if (file) {
    selectedFileName.value = file.name;
    selectedFileSize.value = file.size;

    // Validate file size before processing
    if (file.size > LIMITS.MAX_FILE_SIZE) {
      fileSizeError.value = true;
      uploadForm.value.file = null;
      return;
    }

    fileSizeError.value = false;
    uploadForm.value.file = file;
    if (!uploadForm.value.name) {
      uploadForm.value.name = file.name.replace(/\.[^/.]+$/, '');
    }
  }
};

const triggerFileInput = () => {
  fileInputRef.value?.click();
};

const uploadResource = async () => {
  if (!uploadForm.value.file || isSaving.value) return;

  // In tree view, use selected item's folder path
  let targetFolder = currentFolder.value;
  if (viewMode.value === 'tree' && selectedTreeItem.value) {
    if (selectedTreeItem.value.type === 'folder') {
      targetFolder = selectedTreeItem.value.data.path;
    } else if (selectedTreeItem.value.type === 'file') {
      targetFolder = selectedTreeItem.value.data.folder_path || '/';
    }
  }

  const formData = new FormData();
  formData.append('file', uploadForm.value.file);
  formData.append('name', uploadForm.value.name || uploadForm.value.file.name);
  formData.append('folder_path', targetFolder);
  if (uploadForm.value.description) formData.append('description', uploadForm.value.description);

  // Handle multiple product catalog IDs
  if (uploadForm.value.product_catalog_ids.length > 0) {
    uploadForm.value.product_catalog_ids.forEach(id => {
      formData.append('product_catalog_ids[]', id);
    });
  }

  try {
    await store.dispatch('kbResources/create', formData);
    useAlert(t('KNOWLEDGE_BASE.RESOURCES.UPLOAD.SUCCESS'));
    showUploadModal.value = false;
    await refreshData();
    // Also refresh tree if in tree view
    if (viewMode.value === 'tree') {
      await fetchTreeData();
    }
  } catch (error) {
    const errorMessage = error.response?.data?.error || t('KNOWLEDGE_BASE.RESOURCES.UPLOAD.ERROR');
    useAlert(errorMessage);
  }
};

// Edit modal
const openEditModal = (resource) => {
  editingResource.value = resource;
  // Extract product_catalog_ids from either the direct array or from product_catalogs objects
  const catalogIds = resource.product_catalog_ids?.length
    ? resource.product_catalog_ids
    : (resource.product_catalogs?.map(p => p.id) || []);
  editForm.value = {
    name: resource.name,
    description: resource.description || '',
    product_catalog_ids: catalogIds,
  };
  // Open accordion if there are associations, otherwise closed
  editAccordionOpen.value = catalogIds.length > 0;
  editProductsAccordionOpen.value = false; // Products section starts collapsed
  showEditModal.value = true;
  // Close drawer if open
  selectedResource.value = null;
};

const saveEdit = async () => {
  if (isSaving.value) return;

  try {
    await store.dispatch('kbResources/update', {
      id: editingResource.value.id,
      ...editForm.value,
    });
    useAlert(t('KNOWLEDGE_BASE.RESOURCES.EDIT.SUCCESS'));
    showEditModal.value = false;
    await refreshData();
    // Also refresh tree if in tree view
    if (viewMode.value === 'tree') {
      await fetchTreeData();
    }
  } catch (error) {
    useAlert(t('KNOWLEDGE_BASE.RESOURCES.EDIT.ERROR'));
  }
};

// Delete
const confirmDelete = (resource) => {
  resourceToDelete.value = resource;
  showDeleteModal.value = true;
  // Close drawer if open
  selectedResource.value = null;
};

const executeDelete = async () => {
  if (isDeleting.value) return;

  try {
    await store.dispatch('kbResources/delete', resourceToDelete.value.id);
    useAlert(t('KNOWLEDGE_BASE.RESOURCES.DELETE.SUCCESS'));
    showDeleteModal.value = false;
    await refreshData();
    // Also refresh tree if in tree view (expandedFolders state is preserved)
    if (viewMode.value === 'tree') {
      await fetchTreeData();
    }
  } catch (error) {
    useAlert(t('KNOWLEDGE_BASE.RESOURCES.DELETE.ERROR'));
  }
};

// Toggle visibility
const toggleVisibility = async (resource) => {
  try {
    const wasVisible = resource.is_visible;
    await store.dispatch('kbResources/toggleVisibility', resource.id);
    useAlert(wasVisible
      ? t('KNOWLEDGE_BASE.RESOURCES.VISIBILITY.HIDDEN')
      : t('KNOWLEDGE_BASE.RESOURCES.VISIBILITY.SHOWN')
    );
    // Update selectedResource if it's the same resource (store already updated the record)
    if (selectedResource.value?.id === resource.id) {
      const updated = resources.value.find(r => r.id === resource.id);
      if (updated) {
        selectedResource.value = { ...updated };
      }
    }
    // Update selectedTreeItem if it's the same resource
    if (selectedTreeItem.value?.type === 'file' && selectedTreeItem.value?.data?.id === resource.id) {
      selectedTreeItem.value = {
        ...selectedTreeItem.value,
        data: { ...selectedTreeItem.value.data, is_visible: !wasVisible },
      };
    }
    // Refresh tree if in tree view
    if (viewMode.value === 'tree') {
      await fetchTreeData();
    }
  } catch (error) {
    useAlert(t('KNOWLEDGE_BASE.RESOURCES.VISIBILITY.ERROR'));
  }
};

// Open file
const openFile = (resource) => {
  if (resource.s3_url) {
    window.open(resource.s3_url, '_blank');
  }
};

// Tree view selection
const selectTreeItem = (type, data) => {
  selectedTreeItem.value = { type, data };
  // Open detail drawer when selecting a file in tree view
  if (type === 'file') {
    selectedResource.value = data;
  }
};

const clearTreeSelection = () => {
  selectedTreeItem.value = null;
};

const isTreeItemSelected = (type, id) => {
  return selectedTreeItem.value?.type === type && selectedTreeItem.value?.data?.id === id;
};

// Open folder creation for tree view (with parent path)
const openCreateFolderModalForPath = (parentPath) => {
  parentFolderForNewFolder.value = parentPath;
  newFolderName.value = '';
  showCreateFolderModal.value = true;
};

// Updated createFolder to use parentFolderForNewFolder in tree view
const createFolderFromTree = async () => {
  if (!newFolderName.value.trim() || isCreatingFolder.value || !isFolderNameValid.value) return;

  const folderName = newFolderName.value.trim();
  const parentPath = viewMode.value === 'tree' ? parentFolderForNewFolder.value : currentFolder.value;

  isCreatingFolder.value = true;
  try {
    await store.dispatch('kbResources/createFolder', {
      name: folderName,
      parentPath: parentPath,
    });
    useAlert(t('KNOWLEDGE_BASE.RESOURCES.FOLDER.CREATED'));
    showCreateFolderModal.value = false;

    // Always refresh both views to keep them in sync
    await refreshData();
    await fetchTreeData();

    if (viewMode.value === 'list') {
      // Navigate to the new folder in list view
      const newPath = parentPath === '/' ? `/${folderName}` : `${parentPath}/${folderName}`;
      await navigateToFolder(newPath);
    }
  } catch (error) {
    useAlert(error.response?.data?.error || t('KNOWLEDGE_BASE.RESOURCES.FOLDER.CREATE_ERROR'));
  } finally {
    isCreatingFolder.value = false;
  }
};

// Delete folder
const confirmDeleteFolder = async (folder) => {
  folderToDelete.value = folder;
  folderDeleteConfirmText.value = '';
  folderDeleteRequiresConfirmation.value = false;
  folderDeleteContents.value = { resources: 0, subfolders: 0 };

  // Try to delete without force first to check if empty
  try {
    await store.dispatch('kbResources/deleteFolder', folder.path);
    // If successful, folder was empty
    useAlert(t('KNOWLEDGE_BASE.RESOURCES.FOLDER.DELETED'));
    await refreshData();
    await fetchTreeData();
    clearTreeSelection();
    return;
  } catch (error) {
    const response = error.response?.data;
    if (response?.requires_confirmation) {
      // Folder is not empty, show confirmation modal
      folderDeleteRequiresConfirmation.value = true;
      folderDeleteContents.value = {
        resources: response.resources_count || 0,
        subfolders: response.subfolders_count || 0,
      };
      showDeleteFolderModal.value = true;
      clearTreeSelection();
    } else {
      useAlert(response?.error || t('KNOWLEDGE_BASE.RESOURCES.FOLDER.DELETE_ERROR'));
    }
  }
};

const executeDeleteFolder = async () => {
  if (isDeletingFolder.value || !folderToDelete.value) return;
  if (folderDeleteRequiresConfirmation.value && !isDeletePhraseCorrect.value) return;

  isDeletingFolder.value = true;
  try {
    await store.dispatch('kbResources/deleteFolder', {
      path: folderToDelete.value.path,
      force: folderDeleteRequiresConfirmation.value,
    });
    const { resources, subfolders } = folderDeleteContents.value;
    if (resources > 0 || subfolders > 0) {
      useAlert(t('KNOWLEDGE_BASE.RESOURCES.FOLDER.DELETED_WITH_CONTENTS', { resources, subfolders }));
    } else {
      useAlert(t('KNOWLEDGE_BASE.RESOURCES.FOLDER.DELETED'));
    }
    showDeleteFolderModal.value = false;

    // Always refresh both views to keep them in sync
    await refreshData();
    await fetchTreeData();
  } catch (error) {
    useAlert(error.response?.data?.error || t('KNOWLEDGE_BASE.RESOURCES.FOLDER.DELETE_ERROR'));
  } finally {
    isDeletingFolder.value = false;
  }
};

// Action bar actions for tree view
const handleTreeAction = (action) => {
  if (!selectedTreeItem.value) return;

  const { type, data } = selectedTreeItem.value;

  if (type === 'file') {
    switch (action) {
      case 'open':
        openFile(data);
        break;
      case 'edit':
        openEditModal(data);
        clearTreeSelection();
        break;
      case 'move':
        openMoveModal(data);
        clearTreeSelection();
        break;
      case 'visibility':
        toggleVisibility(data);
        break;
      case 'delete':
        confirmDelete(data);
        clearTreeSelection();
        break;
    }
  } else if (type === 'folder') {
    switch (action) {
      case 'navigate':
        viewMode.value = 'list';
        navigateToFolder(data.path);
        clearTreeSelection();
        break;
      case 'newFolder':
        openCreateFolderModalForPath(data.path);
        clearTreeSelection();
        break;
      case 'delete':
        confirmDeleteFolder(data);
        break;
    }
  }
};

onMounted(fetchData);
</script>

<template>
  <div class="flex-1 overflow-auto bg-n-background">
    <KnowledgeBaseLayout
      :header-title="t('KNOWLEDGE_BASE.RESOURCES.HEADER_TITLE')"
      :button-label="t('KNOWLEDGE_BASE.RESOURCES.UPLOAD_BUTTON')"
      :show-button="!isLoading"
      @click="openUploadModal"
    >
      <!-- Upload Modal -->
      <template #action>
        <Teleport to="body">
          <div
            v-if="showUploadModal"
            class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50"
            @click.self="showUploadModal = false"
          >
            <div
              class="w-full max-w-md bg-n-alpha-3 backdrop-blur-[100px] rounded-xl border border-n-weak shadow-md flex flex-col max-h-[90vh] overflow-hidden"
              @click.stop
            >
              <div class="flex items-center justify-between p-4 sm:p-6 shrink-0">
                <h3 class="text-base font-medium text-n-slate-12">
                  {{ t('KNOWLEDGE_BASE.RESOURCES.UPLOAD.TITLE') }}
                </h3>
                <button class="p-1 text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2 rounded-lg" @click="showUploadModal = false">
                  <i class="i-lucide-x w-5 h-5" />
                </button>
              </div>

              <div class="flex-1 overflow-y-auto px-4 sm:px-6 flex flex-col gap-4">
                <!-- File Upload -->
                <div>
                  <label class="block text-sm font-medium text-n-slate-12 mb-2">
                    {{ t('KNOWLEDGE_BASE.RESOURCES.UPLOAD.SELECT_FILE') }}
                    <span class="text-n-ruby-11">*</span>
                  </label>
                  <input
                    ref="fileInputRef"
                    type="file"
                    accept=".pdf,.doc,.docx,.xls,.xlsx,.txt,.csv,.json,.md,.png,.jpg,.jpeg,.gif,.webp,.svg,.mp3,.wav,.ogg,.m4a,.aac,.flac"
                    class="hidden"
                    @change="handleFileSelect"
                  />
                  <button
                    class="w-full p-4 border-2 border-dashed rounded-lg transition-colors flex flex-col items-center gap-2"
                    :class="fileSizeError ? 'border-n-ruby-9 bg-n-ruby-2' : 'border-n-weak hover:border-n-blue-9'"
                    @click="triggerFileInput"
                  >
                    <i class="i-lucide-upload-cloud w-8 h-8" :class="fileSizeError ? 'text-n-ruby-11' : 'text-n-slate-10'" />
                    <span v-if="selectedFileName" class="text-sm font-medium" :class="fileSizeError ? 'text-n-ruby-11' : 'text-n-slate-12'">
                      {{ selectedFileName }}
                      <span class="text-xs ml-1" :class="fileSizeError ? 'text-n-ruby-10' : 'text-n-slate-10'">
                        ({{ formatFileSize(selectedFileSize) }})
                      </span>
                    </span>
                    <span v-else class="text-sm text-n-slate-11">{{ t('KNOWLEDGE_BASE.RESOURCES.UPLOAD.DROP_OR_CLICK') }}</span>
                    <span class="text-xs text-n-slate-10">{{ t('KNOWLEDGE_BASE.RESOURCES.UPLOAD.FILE_TYPES') }}</span>
                  </button>
                  <!-- File size error message -->
                  <p v-if="fileSizeError" class="mt-2 text-xs text-n-ruby-11 flex items-center gap-1">
                    <i class="i-lucide-alert-circle w-3.5 h-3.5" />
                    {{ t('KNOWLEDGE_BASE.RESOURCES.VALIDATION.FILE_TOO_LARGE', { max: '200MB' }) }}
                  </p>
                </div>

                <div>
                  <Input
                    v-model="uploadForm.name"
                    :label="t('KNOWLEDGE_BASE.RESOURCES.FORM.NAME')"
                    :placeholder="t('KNOWLEDGE_BASE.RESOURCES.FORM.NAME_PLACEHOLDER')"
                    :maxlength="LIMITS.RESOURCE_NAME_MAX"
                  />
                  <div class="flex justify-between mt-1">
                    <span v-if="!isResourceNameValid" class="text-xs text-n-ruby-11">
                      {{ t('KNOWLEDGE_BASE.RESOURCES.VALIDATION.INVALID_NAME') }}
                    </span>
                    <span v-else class="text-xs text-transparent">.</span>
                    <span class="text-xs" :class="uploadForm.name.length > LIMITS.RESOURCE_NAME_MAX ? 'text-n-ruby-11' : 'text-n-slate-10'">
                      {{ uploadForm.name.length }}/{{ LIMITS.RESOURCE_NAME_MAX }}
                    </span>
                  </div>
                </div>

                <div>
                  <Input
                    v-model="uploadForm.description"
                    :label="t('KNOWLEDGE_BASE.RESOURCES.FORM.DESCRIPTION')"
                    :placeholder="t('KNOWLEDGE_BASE.RESOURCES.FORM.DESCRIPTION_PLACEHOLDER')"
                    :maxlength="LIMITS.RESOURCE_DESCRIPTION_MAX"
                  />
                  <div class="flex justify-between mt-1">
                    <span v-if="!isResourceDescriptionValid" class="text-xs text-n-ruby-11">
                      {{ t('KNOWLEDGE_BASE.RESOURCES.VALIDATION.INVALID_DESCRIPTION') }}
                    </span>
                    <span v-else class="text-xs text-transparent">.</span>
                    <span class="text-xs" :class="uploadForm.description.length > LIMITS.RESOURCE_DESCRIPTION_MAX ? 'text-n-ruby-11' : 'text-n-slate-10'">
                      {{ uploadForm.description.length }}/{{ LIMITS.RESOURCE_DESCRIPTION_MAX }}
                    </span>
                  </div>
                </div>

                <!-- Associations Accordion -->
                <div class="border border-n-weak rounded-lg overflow-hidden shrink-0">
                  <button
                    type="button"
                    class="w-full flex items-center justify-between px-3 py-2.5 bg-n-alpha-1 hover:bg-n-alpha-2 transition-colors"
                    @click="uploadAccordionOpen = !uploadAccordionOpen"
                  >
                    <span class="text-sm font-medium text-n-slate-12 flex items-center gap-2">
                      <i class="i-lucide-link w-4 h-4 text-n-slate-10" />
                      {{ t('KNOWLEDGE_BASE.RESOURCES.FORM.ASSOCIATIONS') }}
                      <span class="text-xs text-n-slate-10 font-normal">
                        ({{ uploadForm.product_catalog_ids.length }})
                      </span>
                    </span>
                    <i
                      :class="uploadAccordionOpen ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
                      class="w-4 h-4 text-n-slate-10 transition-transform"
                    />
                  </button>
                  <div v-if="uploadAccordionOpen" class="border-t border-n-weak max-h-[45vh] overflow-y-auto">
                    <!-- Products section (collapsible) -->
                    <div class="border-b border-n-weak last:border-b-0">
                      <!-- Products Header -->
                      <button
                        type="button"
                        class="w-full flex items-center justify-between px-3 py-2 hover:bg-n-alpha-1 transition-colors"
                        @click="uploadProductsAccordionOpen = !uploadProductsAccordionOpen"
                      >
                        <span class="flex items-center gap-2">
                          <i class="i-lucide-package w-3.5 h-3.5 text-n-slate-10" />
                          <span class="text-xs font-medium text-n-slate-11">
                            {{ t('KNOWLEDGE_BASE.RESOURCES.FORM.PRODUCT_CATALOGS') }}
                          </span>
                          <span class="text-xs text-n-slate-10">
                            ({{ uploadForm.product_catalog_ids.length }})
                          </span>
                        </span>
                        <i
                          :class="uploadProductsAccordionOpen ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
                          class="w-4 h-4 text-n-slate-10 transition-transform"
                        />
                      </button>
                      <!-- Products Content -->
                      <div v-if="uploadProductsAccordionOpen" class="px-3 pb-3 max-h-[300px] overflow-y-auto">
                        <ProductSearchSelect
                          v-model="uploadForm.product_catalog_ids"
                          :products="productCatalogs"
                          :placeholder="t('KNOWLEDGE_BASE.RESOURCES.PRODUCT_SEARCH.PLACEHOLDER')"
                        />
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Storage Info -->
                <div class="p-3 bg-n-alpha-2 rounded-lg">
                  <div class="flex justify-between text-xs text-n-slate-11 mb-1">
                    <span>{{ t('KNOWLEDGE_BASE.RESOURCES.STORAGE.USED') }}</span>
                    <span>{{ formatFileSize(storageUsed) }} / {{ formatFileSize(storageLimit) }}</span>
                  </div>
                  <div class="h-2 bg-n-alpha-3 rounded-full overflow-hidden">
                    <div
                      class="h-full bg-n-blue-9 transition-all"
                      :style="{ width: `${storagePercentage}%` }"
                    />
                  </div>
                </div>
              </div>

              <div class="flex gap-3 p-4 sm:p-6 shrink-0">
                <Button variant="outline" :label="t('KNOWLEDGE_BASE.RESOURCES.CANCEL')" class="flex-1" :disabled="isSaving" @click="showUploadModal = false" />
                <Button
                  :label="t('KNOWLEDGE_BASE.RESOURCES.UPLOAD.SUBMIT')"
                  :is-loading="isSaving"
                  :disabled="!uploadForm.file || isSaving || !isResourceNameValid || !isResourceDescriptionValid"
                  class="flex-1"
                  @click="uploadResource"
                />
              </div>
            </div>
          </div>
        </Teleport>
      </template>

      <!-- Top Bar (siempre visible) -->
      <div class="space-y-3">
        <!-- Row 1: Breadcrumbs -->
        <div class="flex items-center gap-1 text-sm overflow-x-auto pb-1 -mb-1">
          <template v-for="(crumb, index) in breadcrumbs" :key="crumb.path">
            <button
              type="button"
              class="flex items-center gap-1 px-2 py-1 rounded-md hover:bg-n-alpha-2 transition-colors whitespace-nowrap shrink-0"
              :class="index === breadcrumbs.length - 1 ? 'text-n-slate-12 font-medium' : 'text-n-slate-11'"
              @click="navigateToFolder(crumb.path)"
            >
              <i v-if="index === 0" class="i-lucide-home w-4 h-4" />
              <i v-else class="i-lucide-folder w-4 h-4" />
              <span class="hidden xs:inline">{{ crumb.name }}</span>
            </button>
            <i v-if="index < breadcrumbs.length - 1" class="i-lucide-chevron-right w-4 h-4 text-n-slate-10 shrink-0" />
          </template>
        </div>

        <!-- Row 2: Actions Bar (responsive) -->
        <div class="flex flex-wrap gap-2 items-center justify-between">
          <!-- Left side: View toggle + Controls -->
          <div class="flex flex-wrap items-center gap-2">
            <!-- View Mode Toggle -->
            <div class="flex items-center border border-n-weak rounded-lg overflow-hidden">
              <button
                type="button"
                class="flex items-center gap-1 px-2 sm:px-3 py-1.5 text-sm transition-colors"
                :class="viewMode === 'list' ? 'bg-n-blue-9 text-white' : 'text-n-slate-11 hover:bg-n-alpha-2'"
                :title="t('KNOWLEDGE_BASE.RESOURCES.VIEW.LIST')"
                @click="viewMode = 'list'"
              >
                <i class="i-lucide-list w-4 h-4" />
              </button>
              <button
                type="button"
                class="flex items-center gap-1 px-2 sm:px-3 py-1.5 text-sm transition-colors"
                :class="viewMode === 'tree' ? 'bg-n-blue-9 text-white' : 'text-n-slate-11 hover:bg-n-alpha-2'"
                :title="t('KNOWLEDGE_BASE.RESOURCES.VIEW.TREE')"
                @click="viewMode = 'tree'"
              >
                <i class="i-lucide-git-branch w-4 h-4" />
              </button>
            </div>

            <!-- New Folder Button -->
            <Button
              variant="faded"
              size="sm"
              color="slate"
              icon="i-lucide-folder-plus"
              class="hidden sm:flex"
              :label="t('KNOWLEDGE_BASE.RESOURCES.FOLDER.NEW')"
              @click="viewMode === 'tree' ? openCreateFolderModalForPath('/') : openCreateFolderModal()"
            />
            <Button
              variant="faded"
              size="sm"
              color="slate"
              icon="i-lucide-folder-plus"
              class="sm:hidden"
              @click="viewMode === 'tree' ? openCreateFolderModalForPath('/') : openCreateFolderModal()"
            />

            <!-- Tree controls (only in tree view) -->
            <template v-if="viewMode === 'tree'">
              <Button
                variant="faded"
                size="sm"
                color="slate"
                icon="i-lucide-chevrons-down-up"
                class="hidden sm:flex"
                :label="t('KNOWLEDGE_BASE.RESOURCES.VIEW.COLLAPSE_ALL')"
                @click="collapseAllFolders"
              />
              <Button
                variant="faded"
                size="sm"
                color="slate"
                icon="i-lucide-chevrons-down-up"
                class="sm:hidden"
                @click="collapseAllFolders"
              />
              <Button
                variant="faded"
                size="sm"
                color="slate"
                icon="i-lucide-chevrons-up-down"
                class="hidden sm:flex"
                :label="t('KNOWLEDGE_BASE.RESOURCES.VIEW.EXPAND_ALL')"
                @click="expandAllFolders"
              />
              <Button
                variant="faded"
                size="sm"
                color="slate"
                icon="i-lucide-chevrons-up-down"
                class="sm:hidden"
                @click="expandAllFolders"
              />
            </template>
          </div>

          <!-- Right side: Search + Storage -->
          <div class="flex flex-wrap items-center gap-2 w-full sm:w-auto">
            <!-- Search (only in list view) -->
            <Input
              v-if="viewMode === 'list'"
              v-model="searchQuery"
              type="search"
              :placeholder="t('KNOWLEDGE_BASE.RESOURCES.SEARCH_PLACEHOLDER')"
              :custom-input-class="[
                'h-8 [&:not(.focus)]:!border-transparent bg-n-alpha-2 dark:bg-n-solid-1 ltr:!pl-8 !py-1 rtl:!pr-8',
              ]"
              class="flex-1 sm:flex-none sm:w-48 min-w-0"
              @enter="handleSearchEnter"
            >
              <template #prefix>
                <Icon
                  icon="i-lucide-search"
                  class="absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-2 rtl:right-2"
                />
              </template>
            </Input>

            <!-- Storage Info -->
            <div class="flex items-center gap-1 sm:gap-2 text-xs text-n-slate-11">
              <i class="i-lucide-hard-drive w-4 h-4 shrink-0" />
              <span class="hidden xs:inline">{{ formatFileSize(storageUsed) }} /</span>
              <span>{{ formatFileSize(storageLimit) }}</span>
              <div class="w-12 sm:w-20 h-1.5 bg-n-alpha-3 rounded-full overflow-hidden shrink-0">
                <div
                  class="h-full bg-n-blue-9 transition-all"
                  :class="{ 'bg-n-amber-9': storagePercentage > 80, 'bg-n-ruby-9': storagePercentage > 95 }"
                  :style="{ width: `${storagePercentage}%` }"
                />
              </div>
            </div>
          </div>
        </div>

        <!-- LIST VIEW -->
        <template v-if="viewMode === 'list'">
          <!-- Loading -->
          <div v-if="isLoading" class="flex items-center justify-center py-10">
            <Spinner />
          </div>

          <!-- Search Loading -->
          <div v-else-if="isSearching" class="flex items-center justify-center py-10">
            <Spinner />
          </div>

          <!-- Empty State -->
          <EmptyStateLayout
            v-else-if="isEmpty"
            :title="t('KNOWLEDGE_BASE.RESOURCES.EMPTY_STATE.TITLE')"
            :subtitle="t('KNOWLEDGE_BASE.RESOURCES.EMPTY_STATE.SUBTITLE')"
          >
          <template #empty-state-item>
            <div class="flex flex-col gap-4 p-px opacity-50 pointer-events-none">
              <div class="flex items-center gap-4 p-4 bg-n-alpha-3 rounded-lg border border-n-weak">
                <i class="i-lucide-file-text w-10 h-10 text-n-slate-10" />
                <div class="flex-1">
                  <div class="text-sm font-medium text-n-slate-12">product-manual.pdf</div>
                  <div class="text-xs text-n-slate-10">2.5 MB</div>
                </div>
              </div>
              <div class="flex items-center gap-4 p-4 bg-n-alpha-3 rounded-lg border border-n-weak">
                <i class="i-lucide-file-spreadsheet w-10 h-10 text-n-slate-10" />
                <div class="flex-1">
                  <div class="text-sm font-medium text-n-slate-12">pricing-guide.xlsx</div>
                  <div class="text-xs text-n-slate-10">1.2 MB</div>
                </div>
              </div>
            </div>
          </template>
        </EmptyStateLayout>

        <!-- No Search Results -->
        <div v-else-if="searchQuery && resources.length === 0 && folders.length === 0" class="flex flex-col items-center justify-center py-16 text-center">
          <i class="i-lucide-search-x w-12 h-12 text-n-slate-9 mb-4" />
          <p class="text-n-slate-11 text-sm">{{ t('KNOWLEDGE_BASE.RESOURCES.NO_SEARCH_RESULTS') }}</p>
        </div>

        <!-- File Browser: Folders + Files -->
        <div v-else class="grid gap-2">
          <!-- Folders (click to select, double-click or chevron to open) -->
          <CardLayout
            v-for="folder in folders"
            :key="folder.path"
            layout="row"
            class="!p-2 sm:!p-3 transition-colors cursor-pointer"
            :class="selectedListFolder?.path === folder.path ? 'bg-n-blue-3 hover:bg-n-blue-4' : 'hover:bg-n-alpha-2'"
            @click="selectListFolder(folder)"
            @dblclick="navigateToFolder(folder.path)"
          >
            <div class="flex items-center gap-2 sm:gap-4 w-full">
              <div class="flex-shrink-0 w-8 h-8 sm:w-10 sm:h-10 rounded-lg bg-n-amber-3 flex items-center justify-center">
                <i class="i-lucide-folder w-4 h-4 sm:w-5 sm:h-5 text-n-amber-11" />
              </div>
              <div class="flex-1 min-w-0">
                <h4 class="text-sm font-medium text-n-slate-12 truncate">{{ folder.name }}</h4>
                <p class="text-xs text-n-slate-10 hidden sm:block">{{ t('KNOWLEDGE_BASE.RESOURCES.FOLDER.LABEL') }}</p>
              </div>
              <!-- Open folder button (works on touch devices) -->
              <button
                type="button"
                class="p-2 hover:bg-n-alpha-3 rounded-lg transition-colors shrink-0"
                :title="t('KNOWLEDGE_BASE.RESOURCES.ACTIONS.OPEN_FOLDER')"
                @click.stop="navigateToFolder(folder.path)"
              >
                <i class="i-lucide-chevron-right w-5 h-5 text-n-slate-10" />
              </button>
            </div>
          </CardLayout>

          <!-- Files -->
          <CardLayout
            v-for="resource in resources"
            :key="resource.id"
            layout="row"
            class="!p-2 sm:!p-3 hover:bg-n-alpha-2 transition-colors cursor-pointer"
            @click="openResourceDetail(resource)"
          >
            <div class="flex items-center gap-2 sm:gap-4 w-full">
              <!-- File Icon -->
              <div class="flex-shrink-0 w-8 h-8 sm:w-10 sm:h-10 rounded-lg bg-n-alpha-2 flex items-center justify-center">
                <i :class="[getFileIcon(resource.content_type), 'w-4 h-4 sm:w-5 sm:h-5 text-n-slate-11']" />
              </div>

              <!-- Info -->
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-1 sm:gap-2">
                  <h4 class="text-sm font-medium text-n-slate-12 truncate">{{ resource.name }}</h4>
                  <span v-if="!resource.is_visible" class="text-xs text-n-amber-11 bg-n-amber-3 px-1 sm:px-1.5 py-0.5 rounded shrink-0">
                    {{ t('KNOWLEDGE_BASE.RESOURCES.HIDDEN') }}
                  </span>
                </div>
                <div class="flex items-center gap-2 sm:gap-3 text-xs text-n-slate-10 mt-0.5">
                  <span class="truncate hidden sm:inline">{{ resource.file_name }}</span>
                  <span class="shrink-0">{{ formatFileSize(resource.file_size) }}</span>
                  <span v-if="resource.product_catalogs?.length" class="text-n-blue-11 shrink-0 hidden md:inline">
                    {{ resource.product_catalogs.length }} {{ resource.product_catalogs.length === 1 ? 'product' : 'products' }}
                  </span>
                </div>
                <p v-if="resource.description" class="text-xs text-n-slate-10 mt-1 truncate hidden sm:block">
                  {{ resource.description }}
                </p>
              </div>

              <!-- Actions - show fewer on mobile -->
              <div class="flex items-center gap-1 flex-shrink-0" @click.stop>
                <!-- Always visible -->
                <Button
                  variant="faded"
                  size="xs"
                  color="slate"
                  icon="i-lucide-external-link"
                  :title="t('KNOWLEDGE_BASE.RESOURCES.OPEN_FILE')"
                  @click="openFile(resource)"
                />
                <!-- Hidden on mobile -->
                <Button
                  variant="faded"
                  size="xs"
                  color="slate"
                  icon="i-lucide-folder-input"
                  class="hidden sm:flex"
                  :title="t('KNOWLEDGE_BASE.RESOURCES.MOVE.TOOLTIP')"
                  @click="openMoveModal(resource)"
                />
                <Button
                  variant="faded"
                  size="xs"
                  color="slate"
                  :icon="resource.is_visible ? 'i-lucide-eye' : 'i-lucide-eye-off'"
                  class="hidden sm:flex"
                  :title="resource.is_visible ? t('KNOWLEDGE_BASE.RESOURCES.HIDE') : t('KNOWLEDGE_BASE.RESOURCES.SHOW')"
                  @click="toggleVisibility(resource)"
                />
                <Button
                  variant="faded"
                  size="xs"
                  color="slate"
                  icon="i-lucide-pencil"
                  class="hidden md:flex"
                  :title="t('KNOWLEDGE_BASE.RESOURCES.EDIT_TOOLTIP')"
                  @click="openEditModal(resource)"
                />
                <Button
                  variant="faded"
                  size="xs"
                  color="ruby"
                  icon="i-lucide-trash"
                  class="hidden md:flex"
                  :title="t('KNOWLEDGE_BASE.RESOURCES.DELETE_TOOLTIP')"
                  @click="confirmDelete(resource)"
                />
              </div>
            </div>
          </CardLayout>
        </div>

        <!-- Pagination -->
        <div v-if="meta && meta.total_pages > 1" class="flex flex-col sm:flex-row items-center justify-between gap-3 mt-6 px-4 py-3 bg-n-solid-1 rounded-lg">
          <div class="hidden sm:block text-sm text-n-slate-11">
            {{ t('KNOWLEDGE_BASE.PRODUCT_CATALOG.PAGINATION.SHOWING') }}
            <span class="font-medium text-n-slate-12">{{ (meta.current_page - 1) * 50 + 1 }}</span>
            {{ t('KNOWLEDGE_BASE.PRODUCT_CATALOG.PAGINATION.TO') }}
            <span class="font-medium text-n-slate-12">{{ Math.min(meta.current_page * 50, meta.total_count) }}</span>
            {{ t('KNOWLEDGE_BASE.PRODUCT_CATALOG.PAGINATION.OF') }}
            <span class="font-medium text-n-slate-12">{{ meta.total_count }}</span>
            {{ t('KNOWLEDGE_BASE.PRODUCT_CATALOG.PAGINATION.RESULTS') }}
          </div>

          <div class="flex items-center gap-1 sm:gap-2 flex-wrap justify-center">
            <button
              :disabled="meta.current_page === 1"
              :class="['px-3 py-1 rounded-md text-sm font-medium transition-colors', meta.current_page === 1 ? 'text-n-slate-9 cursor-not-allowed' : 'text-n-slate-12 hover:bg-n-slate-3']"
              @click="handlePageChange(1)"
            >
              <i class="i-lucide-chevrons-left w-4 h-4" />
            </button>
            <button
              :disabled="meta.current_page === 1"
              :class="['px-3 py-1 rounded-md text-sm font-medium transition-colors', meta.current_page === 1 ? 'text-n-slate-9 cursor-not-allowed' : 'text-n-slate-12 hover:bg-n-slate-3']"
              @click="handlePageChange(meta.current_page - 1)"
            >
              <i class="i-lucide-chevron-left w-4 h-4" />
            </button>

            <div class="flex items-center gap-1">
              <template v-for="page in visiblePages" :key="page">
                <button
                  v-if="typeof page === 'number'"
                  :class="['px-3 py-1 rounded-md text-sm font-medium transition-colors', page === meta.current_page ? 'bg-n-blue-9 text-white' : 'text-n-slate-12 hover:bg-n-slate-3']"
                  @click="handlePageChange(page)"
                >
                  {{ page }}
                </button>
                <span v-else class="px-2 text-n-slate-11">...</span>
              </template>
            </div>

            <button
              :disabled="meta.current_page === meta.total_pages"
              :class="['px-3 py-1 rounded-md text-sm font-medium transition-colors', meta.current_page === meta.total_pages ? 'text-n-slate-9 cursor-not-allowed' : 'text-n-slate-12 hover:bg-n-slate-3']"
              @click="handlePageChange(meta.current_page + 1)"
            >
              <i class="i-lucide-chevron-right w-4 h-4" />
            </button>
            <button
              :disabled="meta.current_page === meta.total_pages"
              :class="['px-3 py-1 rounded-md text-sm font-medium transition-colors', meta.current_page === meta.total_pages ? 'text-n-slate-9 cursor-not-allowed' : 'text-n-slate-12 hover:bg-n-slate-3']"
              @click="handlePageChange(meta.total_pages)"
            >
              <i class="i-lucide-chevrons-right w-4 h-4" />
            </button>
          </div>
        </div>

        <!-- Sticky Action Bar (List View - Folder Selected) -->
        <div
          v-if="selectedListFolder"
          class="sticky bottom-0 z-40 bg-n-solid-1 border border-n-weak rounded-lg shadow-lg mt-4"
        >
          <div class="px-2 sm:px-4 py-2 sm:py-3">
            <div class="flex items-center justify-between gap-2 sm:gap-4">
              <!-- Selected Folder Info -->
              <div class="flex items-center gap-2 min-w-0 flex-1">
                <div class="flex items-center gap-2 px-2 sm:px-3 py-1 sm:py-1.5 bg-n-alpha-2 rounded-lg min-w-0">
                  <i class="i-lucide-folder w-4 h-4 text-n-amber-11 shrink-0" />
                  <span class="text-sm font-medium text-n-slate-12 truncate">
                    {{ selectedListFolder.name }}
                  </span>
                </div>
              </div>

              <!-- Folder Actions -->
              <div class="flex items-center gap-1 sm:gap-2 shrink-0">
                <Button
                  variant="faded"
                  size="sm"
                  color="slate"
                  icon="i-lucide-arrow-right"
                  class="hidden sm:flex"
                  :label="t('KNOWLEDGE_BASE.RESOURCES.ACTIONS.OPEN_FOLDER')"
                  @click="handleListFolderAction('open')"
                />
                <Button
                  variant="faded"
                  size="sm"
                  color="slate"
                  icon="i-lucide-arrow-right"
                  class="sm:hidden"
                  @click="handleListFolderAction('open')"
                />
                <Button
                  variant="faded"
                  size="sm"
                  color="slate"
                  icon="i-lucide-folder-plus"
                  class="hidden sm:flex"
                  :label="t('KNOWLEDGE_BASE.RESOURCES.ACTIONS.NEW_SUBFOLDER')"
                  @click="handleListFolderAction('newSubfolder')"
                />
                <Button
                  variant="faded"
                  size="sm"
                  color="slate"
                  icon="i-lucide-folder-plus"
                  class="sm:hidden"
                  @click="handleListFolderAction('newSubfolder')"
                />
                <Button
                  variant="faded"
                  size="sm"
                  color="ruby"
                  icon="i-lucide-trash"
                  class="hidden sm:flex"
                  :label="t('KNOWLEDGE_BASE.RESOURCES.DRAWER.DELETE')"
                  @click="handleListFolderAction('delete')"
                />
                <Button
                  variant="faded"
                  size="sm"
                  color="ruby"
                  icon="i-lucide-trash"
                  class="sm:hidden"
                  @click="handleListFolderAction('delete')"
                />

                <!-- Close button -->
                <button
                  class="p-1.5 sm:p-2 text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2 rounded-lg"
                  @click="clearListFolderSelection"
                >
                  <i class="i-lucide-x w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        </div>
        </template>

        <!-- TREE VIEW -->
        <template v-else>
          <!-- Tree Loading -->
          <div v-if="isLoadingTree" class="flex items-center justify-center py-10">
            <Spinner />
          </div>

          <!-- Tree Empty State -->
          <div v-else-if="!treeData.folders.length && !treeData.resources.length" class="flex flex-col items-center justify-center py-16 text-center">
            <i class="i-lucide-folder-tree w-12 h-12 text-n-slate-9 mb-4" />
            <p class="text-n-slate-11 text-sm">{{ t('KNOWLEDGE_BASE.RESOURCES.EMPTY_STATE.TITLE') }}</p>
          </div>

          <!-- Tree Structure -->
          <div v-else class="border border-n-weak rounded-lg overflow-hidden bg-n-solid-1 relative">
            <div class="tree-view overflow-x-auto" @click.self="clearTreeSelection">
              <!-- Root header -->
              <div
                class="flex items-center gap-2 px-4 py-3 bg-n-alpha-2 border-b border-n-weak cursor-pointer hover:bg-n-alpha-3 transition-colors"
                @click="toggleFolderExpand('/')"
              >
                <i :class="isFolderExpanded('/') ? 'i-lucide-chevron-down' : 'i-lucide-chevron-right'" class="w-4 h-4 text-n-slate-10 transition-transform" />
                <i class="i-lucide-home w-4 h-4 text-n-amber-11" />
                <span class="font-medium text-n-slate-12">Root</span>
                <span class="text-xs text-n-slate-10 ml-auto">
                  {{ treeData.folders.length }} {{ treeData.folders.length === 1 ? 'folder' : 'folders' }},
                  {{ treeData.resources.length }} {{ treeData.resources.length === 1 ? 'file' : 'files' }}
                </span>
              </div>

              <!-- Root contents (recursive) -->
              <template v-if="isFolderExpanded('/')">
                <!-- Subfolders using recursive component -->
                <TreeNode
                  v-for="folder in treeStructure.children"
                  :key="folder.path"
                  :node="folder"
                  :depth="0"
                  :expanded-folders="expandedFolders"
                  :selected-item="selectedTreeItem"
                  :get-file-icon="getFileIcon"
                  :format-file-size="formatFileSize"
                  @toggle-expand="toggleFolderExpand"
                  @select-folder="(f) => selectTreeItem('folder', f)"
                  @select-file="(f) => selectTreeItem('file', f)"
                />

                <!-- Root level files -->
                <div
                  v-for="file in treeStructure.files"
                  :key="file.id"
                  class="flex items-center gap-2 px-4 py-2 cursor-pointer transition-colors border-b border-n-weak/50 whitespace-nowrap min-w-max"
                  :class="isTreeItemSelected('file', file.id) ? 'bg-n-blue-3 hover:bg-n-blue-4' : 'hover:bg-n-alpha-2'"
                  :style="{ paddingLeft: '1.5rem' }"
                  @click="selectTreeItem('file', file)"
                >
                  <i class="w-5 h-5 shrink-0" />
                  <i :class="[getFileIcon(file.content_type), 'w-4 h-4 text-n-slate-11 shrink-0']" />
                  <span class="text-sm text-n-slate-12">{{ file.name }}</span>
                  <span v-if="!file.is_visible" class="text-xs text-n-amber-11 bg-n-amber-3 px-1 py-0.5 rounded ml-1 shrink-0">{{ t('KNOWLEDGE_BASE.RESOURCES.HIDDEN') }}</span>
                  <span v-if="file.product_catalogs?.length" class="text-xs text-n-blue-11 bg-n-blue-3 px-1 py-0.5 rounded ml-1 shrink-0">
                    {{ file.product_catalogs.length }} {{ file.product_catalogs.length === 1 ? 'product' : 'products' }}
                  </span>
                  <span class="text-xs text-n-slate-10 ml-2 shrink-0">{{ formatFileSize(file.file_size) }}</span>
                </div>
              </template>
            </div>
          </div>

          <!-- Sticky Action Bar (Tree View) - stays within content area -->
          <div
            v-if="selectedTreeItem"
            class="sticky bottom-0 z-40 bg-n-solid-1 border-t border-n-weak shadow-lg"
          >
            <div class="px-2 sm:px-4 py-2 sm:py-3">
              <div class="flex items-center justify-between gap-2 sm:gap-4">
                <!-- Selected Item Info -->
                <div class="flex items-center gap-2 min-w-0 flex-1">
                  <div class="flex items-center gap-2 px-2 sm:px-3 py-1 sm:py-1.5 bg-n-alpha-2 rounded-lg min-w-0">
                    <i :class="selectedTreeItem.type === 'folder' ? 'i-lucide-folder text-n-amber-11' : getFileIcon(selectedTreeItem.data.content_type) + ' text-n-slate-11'" class="w-4 h-4 shrink-0" />
                    <span class="text-sm font-medium text-n-slate-12 truncate">
                      {{ selectedTreeItem.data.name }}
                    </span>
                  </div>
                </div>

                <!-- Actions -->
                <div class="flex items-center gap-1 sm:gap-2 shrink-0">
                  <!-- File Actions -->
                  <template v-if="selectedTreeItem.type === 'file'">
                    <Button variant="faded" size="sm" color="slate" icon="i-lucide-external-link" class="hidden sm:flex" :label="t('KNOWLEDGE_BASE.RESOURCES.DRAWER.OPEN_FILE')" @click="handleTreeAction('open')" />
                    <Button variant="faded" size="sm" color="slate" icon="i-lucide-external-link" class="sm:hidden" @click="handleTreeAction('open')" />
                    <Button variant="faded" size="sm" color="slate" icon="i-lucide-pencil" class="hidden sm:flex" :label="t('KNOWLEDGE_BASE.RESOURCES.DRAWER.EDIT')" @click="handleTreeAction('edit')" />
                    <Button variant="faded" size="sm" color="slate" icon="i-lucide-pencil" class="sm:hidden" @click="handleTreeAction('edit')" />
                    <Button variant="faded" size="sm" color="slate" icon="i-lucide-folder-input" class="hidden md:flex" :label="t('KNOWLEDGE_BASE.RESOURCES.MOVE.BUTTON')" @click="handleTreeAction('move')" />
                    <Button variant="faded" size="sm" color="slate" icon="i-lucide-folder-input" class="md:hidden" @click="handleTreeAction('move')" />
                    <Button variant="faded" size="sm" color="slate" :icon="selectedTreeItem.data.is_visible ? 'i-lucide-eye' : 'i-lucide-eye-off'" class="hidden md:flex" :label="selectedTreeItem.data.is_visible ? t('KNOWLEDGE_BASE.RESOURCES.HIDE') : t('KNOWLEDGE_BASE.RESOURCES.SHOW')" @click="handleTreeAction('visibility')" />
                    <Button variant="faded" size="sm" color="slate" :icon="selectedTreeItem.data.is_visible ? 'i-lucide-eye' : 'i-lucide-eye-off'" class="md:hidden" @click="handleTreeAction('visibility')" />
                    <Button variant="faded" size="sm" color="ruby" icon="i-lucide-trash" class="hidden sm:flex" :label="t('KNOWLEDGE_BASE.RESOURCES.DRAWER.DELETE')" @click="handleTreeAction('delete')" />
                    <Button variant="faded" size="sm" color="ruby" icon="i-lucide-trash" class="sm:hidden" @click="handleTreeAction('delete')" />
                  </template>

                  <!-- Folder Actions -->
                  <template v-else>
                    <Button variant="faded" size="sm" color="slate" icon="i-lucide-arrow-right" class="hidden sm:flex" :label="t('KNOWLEDGE_BASE.RESOURCES.ACTIONS.OPEN_FOLDER')" @click="handleTreeAction('navigate')" />
                    <Button variant="faded" size="sm" color="slate" icon="i-lucide-arrow-right" class="sm:hidden" @click="handleTreeAction('navigate')" />
                    <Button variant="faded" size="sm" color="slate" icon="i-lucide-folder-plus" class="hidden sm:flex" :label="t('KNOWLEDGE_BASE.RESOURCES.ACTIONS.NEW_SUBFOLDER')" @click="handleTreeAction('newFolder')" />
                    <Button variant="faded" size="sm" color="slate" icon="i-lucide-folder-plus" class="sm:hidden" @click="handleTreeAction('newFolder')" />
                    <Button variant="faded" size="sm" color="ruby" icon="i-lucide-trash" class="hidden sm:flex" :label="t('KNOWLEDGE_BASE.RESOURCES.DRAWER.DELETE')" @click="handleTreeAction('delete')" />
                    <Button variant="faded" size="sm" color="ruby" icon="i-lucide-trash" class="sm:hidden" @click="handleTreeAction('delete')" />
                  </template>

                  <!-- Close button -->
                  <button
                    class="p-1.5 sm:p-2 text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2 rounded-lg"
                    @click="clearTreeSelection"
                  >
                    <i class="i-lucide-x w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </template>
      </div>
    </KnowledgeBaseLayout>

    <!-- Edit Modal -->
    <Teleport to="body">
      <div
        v-if="showEditModal"
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50"
        @click.self="showEditModal = false"
      >
        <div
          class="w-full max-w-md bg-n-alpha-3 backdrop-blur-[100px] rounded-xl border border-n-weak shadow-md flex flex-col max-h-[90vh] overflow-hidden"
          @click.stop
        >
          <div class="flex items-center justify-between p-4 sm:p-6 shrink-0">
            <h3 class="text-base font-medium text-n-slate-12">
              {{ t('KNOWLEDGE_BASE.RESOURCES.EDIT.TITLE') }}
            </h3>
            <button class="p-1 text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2 rounded-lg" @click="showEditModal = false">
              <i class="i-lucide-x w-5 h-5" />
            </button>
          </div>

          <div class="flex-1 overflow-y-auto px-4 sm:px-6 flex flex-col gap-4">
            <div>
              <Input
                v-model="editForm.name"
                :label="t('KNOWLEDGE_BASE.RESOURCES.FORM.NAME')"
                :placeholder="t('KNOWLEDGE_BASE.RESOURCES.FORM.NAME_PLACEHOLDER')"
                :maxlength="LIMITS.RESOURCE_NAME_MAX"
              />
              <div class="flex justify-between mt-1">
                <span v-if="!isEditNameValid" class="text-xs text-n-ruby-11">
                  {{ t('KNOWLEDGE_BASE.RESOURCES.VALIDATION.INVALID_NAME') }}
                </span>
                <span v-else class="text-xs text-transparent">.</span>
                <span class="text-xs" :class="editForm.name.length > LIMITS.RESOURCE_NAME_MAX ? 'text-n-ruby-11' : 'text-n-slate-10'">
                  {{ editForm.name.length }}/{{ LIMITS.RESOURCE_NAME_MAX }}
                </span>
              </div>
            </div>

            <div>
              <Input
                v-model="editForm.description"
                :label="t('KNOWLEDGE_BASE.RESOURCES.FORM.DESCRIPTION')"
                :placeholder="t('KNOWLEDGE_BASE.RESOURCES.FORM.DESCRIPTION_PLACEHOLDER')"
                :maxlength="LIMITS.RESOURCE_DESCRIPTION_MAX"
              />
              <div class="flex justify-between mt-1">
                <span v-if="!isEditDescriptionValid" class="text-xs text-n-ruby-11">
                  {{ t('KNOWLEDGE_BASE.RESOURCES.VALIDATION.INVALID_DESCRIPTION') }}
                </span>
                <span v-else class="text-xs text-transparent">.</span>
                <span class="text-xs" :class="editForm.description.length > LIMITS.RESOURCE_DESCRIPTION_MAX ? 'text-n-ruby-11' : 'text-n-slate-10'">
                  {{ editForm.description.length }}/{{ LIMITS.RESOURCE_DESCRIPTION_MAX }}
                </span>
              </div>
            </div>

            <!-- Associations Accordion -->
            <div class="border border-n-weak rounded-lg overflow-hidden shrink-0">
              <button
                type="button"
                class="w-full flex items-center justify-between px-3 py-2.5 bg-n-alpha-1 hover:bg-n-alpha-2 transition-colors"
                @click="editAccordionOpen = !editAccordionOpen"
              >
                <span class="text-sm font-medium text-n-slate-12 flex items-center gap-2">
                  <i class="i-lucide-link w-4 h-4 text-n-slate-10" />
                  {{ t('KNOWLEDGE_BASE.RESOURCES.FORM.ASSOCIATIONS') }}
                  <span class="text-xs text-n-slate-10 font-normal">
                    ({{ editForm.product_catalog_ids.length }})
                  </span>
                </span>
                <i
                  :class="editAccordionOpen ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
                  class="w-4 h-4 text-n-slate-10 transition-transform"
                />
              </button>
              <div v-if="editAccordionOpen" class="border-t border-n-weak max-h-[45vh] overflow-y-auto">
                <!-- Products section (collapsible) -->
                <div class="border-b border-n-weak last:border-b-0">
                  <!-- Products Header -->
                  <button
                    type="button"
                    class="w-full flex items-center justify-between px-3 py-2 hover:bg-n-alpha-1 transition-colors"
                    @click="editProductsAccordionOpen = !editProductsAccordionOpen"
                  >
                    <span class="flex items-center gap-2">
                      <i class="i-lucide-package w-3.5 h-3.5 text-n-slate-10" />
                      <span class="text-xs font-medium text-n-slate-11">
                        {{ t('KNOWLEDGE_BASE.RESOURCES.FORM.PRODUCT_CATALOGS') }}
                      </span>
                      <span class="text-xs text-n-slate-10">
                        ({{ editForm.product_catalog_ids.length }})
                      </span>
                    </span>
                    <i
                      :class="editProductsAccordionOpen ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
                      class="w-4 h-4 text-n-slate-10 transition-transform"
                    />
                  </button>
                  <!-- Products Content -->
                  <div v-if="editProductsAccordionOpen" class="px-3 pb-3 max-h-[300px] overflow-y-auto">
                    <ProductSearchSelect
                      v-model="editForm.product_catalog_ids"
                      :products="productCatalogs"
                      :placeholder="t('KNOWLEDGE_BASE.RESOURCES.PRODUCT_SEARCH.PLACEHOLDER')"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="flex gap-3 p-4 sm:p-6 shrink-0">
            <Button variant="outline" :label="t('KNOWLEDGE_BASE.RESOURCES.CANCEL')" class="flex-1" :disabled="isSaving" @click="showEditModal = false" />
            <Button
              :label="t('KNOWLEDGE_BASE.RESOURCES.SAVE')"
              :is-loading="isSaving"
              :disabled="!editForm.name || isSaving || !isEditNameValid || !isEditDescriptionValid"
              class="flex-1"
              @click="saveEdit"
            />
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Delete Modal -->
    <div v-if="showDeleteModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50" @click.self="showDeleteModal = false">
      <div class="bg-n-solid-1 rounded-xl shadow-xl w-full max-w-md mx-4">
        <div class="flex items-center gap-3 px-6 py-4 border-b border-n-weak">
          <div class="p-2 rounded-full bg-n-ruby-3">
            <i class="i-lucide-trash-2 w-5 h-5 text-n-ruby-11" />
          </div>
          <h2 class="text-lg font-semibold text-n-slate-12">
            {{ t('KNOWLEDGE_BASE.RESOURCES.DELETE.TITLE') }}
          </h2>
        </div>
        <div class="px-6 py-4">
          <p class="text-sm text-n-slate-11 mb-3">
            {{ t('KNOWLEDGE_BASE.RESOURCES.DELETE.CONFIRM') }}
          </p>
          <div class="p-3 bg-n-alpha-2 rounded-lg">
            <p class="text-sm font-medium text-n-slate-12 truncate">
              {{ resourceToDelete?.name }}
            </p>
          </div>
        </div>
        <div class="flex justify-end gap-2 px-6 py-4 border-t border-n-weak">
          <Button variant="faded" color="slate" :label="t('KNOWLEDGE_BASE.RESOURCES.CANCEL')" :disabled="isDeleting" @click="showDeleteModal = false" />
          <Button color="ruby" :label="t('KNOWLEDGE_BASE.RESOURCES.DELETE.BUTTON')" :is-loading="isDeleting" :disabled="isDeleting" @click="executeDelete" />
        </div>
      </div>
    </div>

    <!-- Resource Detail Drawer -->
    <ResourceDetailDrawer
      :resource="selectedResource"
      @close="closeResourceDetail"
      @edit="openEditModal"
      @delete="confirmDelete"
      @toggle-visibility="toggleVisibility"
      @move="openMoveModal"
    />

    <!-- Create Folder Modal (z-60 to appear above Move modal) -->
    <Teleport to="body">
      <div
        v-if="showCreateFolderModal"
        class="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/50"
        @click.self="showCreateFolderModal = false"
      >
        <div
          class="w-full max-w-sm bg-n-alpha-3 backdrop-blur-[100px] rounded-xl border border-n-weak shadow-xl"
          @click.stop
        >
          <div class="flex items-center justify-between p-4">
            <h3 class="text-base font-medium text-n-slate-12">
              {{ t('KNOWLEDGE_BASE.RESOURCES.FOLDER.NEW_TITLE') }}
            </h3>
            <button class="p-1 text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2 rounded-lg" @click="showCreateFolderModal = false">
              <i class="i-lucide-x w-5 h-5" />
            </button>
          </div>

          <div class="px-4 pb-4">
            <div>
              <Input
                v-model="newFolderName"
                :label="t('KNOWLEDGE_BASE.RESOURCES.FOLDER.NAME')"
                :placeholder="t('KNOWLEDGE_BASE.RESOURCES.FOLDER.NAME_PLACEHOLDER')"
                :maxlength="LIMITS.FOLDER_NAME_MAX"
                @keyup.enter="isFolderNameValid && createFolder()"
              />
              <div class="flex justify-between mt-1">
                <span v-if="newFolderName && !isFolderNameValid" class="text-xs text-n-ruby-11">
                  {{ t('KNOWLEDGE_BASE.RESOURCES.VALIDATION.INVALID_FOLDER_NAME') }}
                </span>
                <span v-else class="text-xs text-transparent">.</span>
                <span class="text-xs" :class="newFolderName.length > LIMITS.FOLDER_NAME_MAX ? 'text-n-ruby-11' : 'text-n-slate-10'">
                  {{ newFolderName.length }}/{{ LIMITS.FOLDER_NAME_MAX }}
                </span>
              </div>
            </div>
            <p class="text-xs text-n-slate-10 mt-2 break-all">
              {{ t('KNOWLEDGE_BASE.RESOURCES.FOLDER.LOCATION') }}: <span class="font-mono">{{ parentFolderForNewFolder }}</span>
            </p>
          </div>

          <div class="flex gap-3 p-4 border-t border-n-weak">
            <Button variant="outline" :label="t('KNOWLEDGE_BASE.RESOURCES.CANCEL')" class="flex-1" :disabled="isCreatingFolder" @click="showCreateFolderModal = false" />
            <Button
              :label="t('KNOWLEDGE_BASE.RESOURCES.FOLDER.CREATE')"
              :disabled="!newFolderName.trim() || isCreatingFolder || !isFolderNameValid"
              :is-loading="isCreatingFolder"
              class="flex-1"
              @click="createFolder"
            />
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Delete Folder Modal (with force confirmation for non-empty folders) -->
    <div v-if="showDeleteFolderModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50" @click.self="showDeleteFolderModal = false">
      <div class="bg-n-solid-1 rounded-xl shadow-xl w-full max-w-md mx-4">
        <div class="flex items-center gap-3 px-6 py-4 border-b border-n-weak">
          <div class="p-2 rounded-full bg-n-ruby-3">
            <i class="i-lucide-folder-x w-5 h-5 text-n-ruby-11" />
          </div>
          <h2 class="text-lg font-semibold text-n-slate-12">
            {{ t('KNOWLEDGE_BASE.RESOURCES.FOLDER.DELETE_TITLE') }}
          </h2>
        </div>
        <div class="px-6 py-4">
          <!-- Warning for non-empty folder -->
          <div v-if="folderDeleteRequiresConfirmation" class="mb-4 p-3 bg-n-ruby-3 border border-n-ruby-6 rounded-lg">
            <div class="flex items-start gap-2">
              <i class="i-lucide-alert-triangle w-5 h-5 text-n-ruby-11 shrink-0 mt-0.5" />
              <div>
                <p class="text-sm font-medium text-n-ruby-11">
                  {{ t('KNOWLEDGE_BASE.RESOURCES.FOLDER.NOT_EMPTY_WARNING') }}
                </p>
                <p class="text-xs text-n-ruby-10 mt-1">
                  {{ t('KNOWLEDGE_BASE.RESOURCES.FOLDER.CONTENTS_INFO', {
                    resources: folderDeleteContents.resources,
                    subfolders: folderDeleteContents.subfolders
                  }) }}
                </p>
              </div>
            </div>
          </div>

          <p class="text-sm text-n-slate-11 mb-3">
            {{ folderDeleteRequiresConfirmation
              ? t('KNOWLEDGE_BASE.RESOURCES.FOLDER.DELETE_CONFIRM_FORCE')
              : t('KNOWLEDGE_BASE.RESOURCES.FOLDER.DELETE_CONFIRM')
            }}
          </p>

          <div class="p-3 bg-n-alpha-2 rounded-lg flex items-center gap-2">
            <i class="i-lucide-folder w-5 h-5 text-n-amber-11" />
            <p class="text-sm font-medium text-n-slate-12 truncate">
              {{ folderToDelete?.name }}
            </p>
          </div>

          <!-- Confirmation phrase input -->
          <div v-if="folderDeleteRequiresConfirmation" class="mt-4">
            <label class="block text-sm text-n-slate-11 mb-2">
              {{ t('KNOWLEDGE_BASE.RESOURCES.FOLDER.TYPE_TO_CONFIRM') }}
              <code class="px-1.5 py-0.5 bg-n-alpha-3 rounded text-n-ruby-11 font-mono text-xs">{{ expectedDeletePhrase }}</code>
            </label>
            <Input
              v-model="folderDeleteConfirmText"
              :placeholder="expectedDeletePhrase"
              class="w-full"
              @keyup.enter="isDeletePhraseCorrect && executeDeleteFolder()"
            />
          </div>

          <p v-if="!folderDeleteRequiresConfirmation" class="text-xs text-n-slate-10 mt-2">
            {{ t('KNOWLEDGE_BASE.RESOURCES.FOLDER.DELETE_WARNING') }}
          </p>
        </div>
        <div class="flex justify-end gap-2 px-6 py-4 border-t border-n-weak">
          <Button
            variant="faded"
            color="slate"
            :label="t('KNOWLEDGE_BASE.RESOURCES.CANCEL')"
            :disabled="isDeletingFolder"
            @click="showDeleteFolderModal = false"
          />
          <Button
            color="ruby"
            :label="t('KNOWLEDGE_BASE.RESOURCES.DELETE.BUTTON')"
            :is-loading="isDeletingFolder"
            :disabled="isDeletingFolder || (folderDeleteRequiresConfirmation && !isDeletePhraseCorrect)"
            @click="executeDeleteFolder"
          />
        </div>
      </div>
    </div>

    <!-- Move Resource Modal -->
    <Teleport to="body">
      <div
        v-if="showMoveModal"
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm"
        @click.self="showMoveModal = false"
      >
        <div
          class="w-full max-w-sm bg-n-solid-3 rounded-xl border border-n-weak shadow-xl flex flex-col max-h-[80vh]"
          @click.stop
        >
          <!-- Header -->
          <div class="p-4 pb-2">
            <h3 class="text-lg font-medium text-n-slate-12">
              {{ t('KNOWLEDGE_BASE.RESOURCES.MOVE.TITLE') }}
            </h3>
            <p class="text-sm text-n-slate-11 mt-1">
              {{ t('KNOWLEDGE_BASE.RESOURCES.MOVE.CHOOSE_DESTINATION') }}
            </p>
          </div>

          <!-- Folder Browser -->
          <div class="flex-1 overflow-y-auto px-4">
            <!-- Go up (..) -->
            <button
              v-if="moveBrowserPath !== '/'"
              type="button"
              class="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg transition-colors bg-n-blue-3 hover:bg-n-blue-4 mb-1"
              @click="moveBrowserGoUp"
            >
              <i class="i-lucide-folder w-5 h-5 text-n-amber-9" />
              <span class="text-sm text-n-slate-12">..</span>
            </button>

            <!-- Subfolders -->
            <button
              v-for="folder in moveBrowserFolders"
              :key="folder.path"
              type="button"
              class="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg transition-colors hover:bg-n-alpha-2"
              :class="moveTargetFolder === folder.path ? 'bg-n-blue-3' : ''"
              @click="moveBrowserNavigateTo(folder.path)"
            >
              <i class="i-lucide-folder w-5 h-5 text-n-slate-10" />
              <span class="text-sm text-n-slate-12">{{ folder.name }}</span>
            </button>

            <!-- Empty state -->
            <div v-if="moveBrowserFolders.length === 0 && moveBrowserPath === '/'" class="py-4 text-center text-sm text-n-slate-10">
              {{ t('KNOWLEDGE_BASE.RESOURCES.CATEGORIES.EMPTY') }}
            </div>
          </div>

          <!-- Current location -->
          <div class="px-4 py-3">
            <p class="text-sm text-n-slate-11 break-all">
              {{ t('KNOWLEDGE_BASE.RESOURCES.MOVE.CURRENT_LOCATION') }}:
              <span class="font-mono text-n-blue-11">{{ moveBrowserPath }}</span>
            </p>
          </div>

          <!-- Actions -->
          <div class="flex items-center gap-4 px-4 py-3 border-t border-n-weak">
            <button
              type="button"
              class="text-sm font-medium text-n-blue-11 hover:text-n-blue-12 transition-colors"
              @click="parentFolderForNewFolder = moveBrowserPath; newFolderName = ''; showCreateFolderModal = true;"
            >
              {{ t('KNOWLEDGE_BASE.RESOURCES.MOVE.NEW_FOLDER') }}
            </button>
            <div class="flex-1" />
            <button
              type="button"
              class="text-sm font-medium text-n-slate-11 hover:text-n-slate-12 transition-colors"
              :disabled="isMoving"
              @click="showMoveModal = false"
            >
              {{ t('KNOWLEDGE_BASE.RESOURCES.CANCEL') }}
            </button>
            <button
              type="button"
              class="text-sm font-medium text-n-blue-11 hover:text-n-blue-12 transition-colors disabled:opacity-50"
              :disabled="isMoving"
              @click="moveResource"
            >
              {{ isMoving ? '...' : t('KNOWLEDGE_BASE.RESOURCES.MOVE.BUTTON') }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>
