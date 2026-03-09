import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import VueRouter from 'vue-router';
import PackDetails from './PackDetails.vue';

const localVue = createLocalVue();
localVue.use(Vuex);
localVue.use(VueRouter);

const router = new VueRouter({
  routes: [
    {
      path: '/accounts/:accountId/settings/stickers/packs/:packName',
      name: 'sticker_pack_details',
    },
    {
      path: '/accounts/:accountId/settings/stickers',
      name: 'sticker_management',
    },
  ],
});

describe('PackDetails', () => {
  let store;
  let actions;
  let getters;
  let wrapper;

  const mockStickers = [
    {
      id: 1,
      url: 'http://example.com/sticker1.webp',
      filename: 'sticker1.webp',
      size: 1024,
      created_at: '2024-01-01T00:00:00Z',
    },
    {
      id: 2,
      url: 'http://example.com/sticker2.webp',
      filename: 'sticker2.webp',
      size: 2048,
      created_at: '2024-01-02T00:00:00Z',
    },
  ];

  beforeEach(() => {
    actions = {};
    getters = {
      getCurrentAccountId: () => 1,
    };

    store = new Vuex.Store({
      actions,
      getters,
    });

    // Set up route params
    router.push('/accounts/1/settings/stickers/packs/Test%20Pack');

    wrapper = mount(PackDetails, {
      store,
      localVue,
      router,
      mocks: {
        $t: key => key,
        $http: {
          get: vi.fn(),
          post: vi.fn(),
          delete: vi.fn(),
        },
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('component rendering', () => {
    it('renders pack name in header', () => {
      expect(wrapper.find('.page-title').text()).toBe('Test Pack');
    });

    it('renders back button', () => {
      const backButton = wrapper.find('[data-testid="back-button"]');
      expect(backButton.exists()).toBe(true);
    });

    it('renders action buttons', () => {
      expect(wrapper.find('[data-testid="bulk-upload-button"]').exists()).toBe(
        true
      );
      expect(wrapper.find('[data-testid="add-sticker-button"]').exists()).toBe(
        true
      );
    });

    it('shows loading state when fetching stickers', async () => {
      wrapper.setData({ isLoading: true });
      await wrapper.vm.$nextTick();

      expect(wrapper.find('.loading-state').exists()).toBe(true);
    });

    it('shows empty state when no stickers exist', async () => {
      wrapper.setData({ isLoading: false, stickers: [] });
      await wrapper.vm.$nextTick();

      expect(wrapper.find('.empty-state').exists()).toBe(true);
      expect(wrapper.find('.empty-state h3').text()).toBe(
        'STICKER_MANAGEMENT.EMPTY_PACK.TITLE'
      );
    });

    it('renders stickers grid when stickers exist', async () => {
      wrapper.setData({
        isLoading: false,
        stickers: mockStickers,
        totalStickers: 2,
      });
      await wrapper.vm.$nextTick();

      expect(wrapper.find('.stickers-grid').exists()).toBe(true);
      expect(wrapper.findAll('.sticker-item')).toHaveLength(2);
    });
  });

  describe('API interactions', () => {
    it('fetches pack details on mount', () => {
      expect(wrapper.vm.$http.get).toHaveBeenCalledWith(
        '/api/v1/accounts/1/sticker_packs/Test Pack'
      );
    });

    it('handles fetch error gracefully', async () => {
      const consoleSpy = vi.spyOn(console, 'error').mockImplementation();
      wrapper.vm.$http.get.mockRejectedValue(new Error('Network error'));

      await wrapper.vm.fetchPackDetails();

      expect(wrapper.vm.isLoading).toBe(false);
      consoleSpy.mockRestore();
    });
  });

  describe('navigation', () => {
    it('navigates back to sticker management when back button is clicked', async () => {
      const backButton = wrapper.find('[data-testid="back-button"]');
      await backButton.trigger('click');

      expect(wrapper.vm.$router.currentRoute.name).toBe('sticker_management');
    });
  });

  describe('single file upload', () => {
    it('opens upload modal when add sticker button is clicked', async () => {
      const addButton = wrapper.find('[data-testid="add-sticker-button"]');
      await addButton.trigger('click');

      expect(wrapper.vm.showUploadModal).toBe(true);
    });

    it('processes selected file correctly', async () => {
      const mockFile = new File(['test'], 'test.png', { type: 'image/png' });

      // Mock URL.createObjectURL
      global.URL.createObjectURL = vi.fn(() => 'blob:test-url');

      await wrapper.vm.processSelectedFile(mockFile);

      expect(wrapper.vm.selectedFile).toBe(mockFile);
      expect(wrapper.vm.previewUrl).toBe('blob:test-url');
    });

    it('validates file after selection', async () => {
      const mockFile = new File(['test'], 'test.png', { type: 'image/png' });
      wrapper.vm.$http.post.mockResolvedValue({
        data: { valid: true, preview_url: 'test-url' },
      });

      await wrapper.vm.validateFile(mockFile);

      expect(wrapper.vm.$http.post).toHaveBeenCalledWith(
        '/api/v1/accounts/1/admin/stickers/validate_file',
        expect.any(FormData),
        expect.objectContaining({
          headers: { 'Content-Type': 'multipart/form-data' },
        })
      );
      expect(wrapper.vm.validationResult.valid).toBe(true);
    });

    it('uploads sticker successfully', async () => {
      const mockFile = new File(['test'], 'test.png', { type: 'image/png' });
      wrapper.setData({
        selectedFile: mockFile,
        stickerTags: 'test, sample',
        showUploadModal: true,
      });

      wrapper.vm.$http.post.mockResolvedValue({
        data: { id: 1, url: 'test.webp' },
      });

      await wrapper.vm.uploadSticker();

      expect(wrapper.vm.$http.post).toHaveBeenCalledWith(
        '/api/v1/accounts/1/admin/stickers',
        expect.any(FormData),
        expect.objectContaining({
          headers: { 'Content-Type': 'multipart/form-data' },
        })
      );
      expect(wrapper.vm.showUploadModal).toBe(false);
    });
  });

  describe('bulk upload', () => {
    it('opens bulk upload modal when bulk upload button is clicked', async () => {
      const bulkButton = wrapper.find('[data-testid="bulk-upload-button"]');
      await bulkButton.trigger('click');

      expect(wrapper.vm.showBulkUploadModal).toBe(true);
    });

    it('handles multiple file selection', () => {
      const mockFiles = [
        new File(['test1'], 'test1.png', { type: 'image/png' }),
        new File(['test2'], 'test2.png', { type: 'image/png' }),
      ];

      const mockEvent = { target: { files: mockFiles } };
      wrapper.vm.handleBulkFileSelect(mockEvent);

      expect(wrapper.vm.selectedFiles).toEqual(mockFiles);
    });

    it('removes file from selection', () => {
      const mockFiles = [
        new File(['test1'], 'test1.png', { type: 'image/png' }),
        new File(['test2'], 'test2.png', { type: 'image/png' }),
      ];

      wrapper.setData({ selectedFiles: mockFiles });
      wrapper.vm.removeFile(0);

      expect(wrapper.vm.selectedFiles).toHaveLength(1);
      expect(wrapper.vm.selectedFiles[0].name).toBe('test2.png');
    });

    it('uploads multiple stickers successfully', async () => {
      const mockFiles = [
        new File(['test1'], 'test1.png', { type: 'image/png' }),
        new File(['test2'], 'test2.png', { type: 'image/png' }),
      ];

      wrapper.setData({ selectedFiles: mockFiles });

      wrapper.vm.$http.post.mockResolvedValue({
        data: {
          successful: 2,
          failed: 0,
          results: [
            { index: 0, id: 1 },
            { index: 1, id: 2 },
          ],
          errors: [],
        },
      });

      await wrapper.vm.bulkUploadStickers();

      expect(wrapper.vm.$http.post).toHaveBeenCalledWith(
        '/api/v1/accounts/1/sticker_packs/bulk_upload',
        expect.any(FormData),
        expect.objectContaining({
          headers: { 'Content-Type': 'multipart/form-data' },
        })
      );

      // Check progress updates
      expect(wrapper.vm.bulkUploadProgress[0].status).toBe('success');
      expect(wrapper.vm.bulkUploadProgress[1].status).toBe('success');
    });
  });

  describe('sticker management', () => {
    beforeEach(() => {
      wrapper.setData({ stickers: mockStickers });
    });

    it('opens delete modal when delete button is clicked', async () => {
      const deleteButton = wrapper.find(
        '[data-testid="delete-sticker-button"]'
      );
      await deleteButton.trigger('click');

      expect(wrapper.vm.showDeleteModal).toBe(true);
      expect(wrapper.vm.deletingSticker).toEqual(mockStickers[0]);
    });

    it('deletes sticker successfully', async () => {
      wrapper.setData({
        deletingSticker: mockStickers[0],
        showDeleteModal: true,
      });

      wrapper.vm.$http.delete.mockResolvedValue({
        data: { message: 'Sticker deleted successfully' },
      });

      await wrapper.vm.confirmDeleteSticker();

      expect(wrapper.vm.$http.delete).toHaveBeenCalledWith(
        '/api/v1/accounts/1/admin/stickers/1'
      );
      expect(wrapper.vm.showDeleteModal).toBe(false);
    });
  });

  describe('utility methods', () => {
    it('formats file size correctly', () => {
      expect(wrapper.vm.formatFileSize(0)).toBe('0 Bytes');
      expect(wrapper.vm.formatFileSize(1024)).toBe('1 KB');
      expect(wrapper.vm.formatFileSize(1048576)).toBe('1 MB');
      expect(wrapper.vm.formatFileSize(1073741824)).toBe('1 GB');
    });

    it('gets file preview URL', () => {
      const mockFile = new File(['test'], 'test.png', { type: 'image/png' });
      global.URL.createObjectURL = vi.fn(() => 'blob:test-url');

      const previewUrl = wrapper.vm.getFilePreviewUrl(mockFile);

      expect(previewUrl).toBe('blob:test-url');
      expect(global.URL.createObjectURL).toHaveBeenCalledWith(mockFile);
    });
  });

  describe('drag and drop', () => {
    it('handles single file drop', () => {
      const mockFile = new File(['test'], 'test.png', { type: 'image/png' });
      const mockEvent = {
        dataTransfer: { files: [mockFile] },
        preventDefault: vi.fn(),
      };

      wrapper.vm.handleFileDrop(mockEvent);

      expect(wrapper.vm.isDragOver).toBe(false);
      expect(wrapper.vm.selectedFile).toBe(mockFile);
    });

    it('handles bulk file drop', () => {
      const mockFiles = [
        new File(['test1'], 'test1.png', { type: 'image/png' }),
        new File(['test2'], 'test2.png', { type: 'image/png' }),
      ];
      const mockEvent = {
        dataTransfer: { files: mockFiles },
        preventDefault: vi.fn(),
      };

      wrapper.vm.handleBulkFileDrop(mockEvent);

      expect(wrapper.vm.isBulkDragOver).toBe(false);
      expect(wrapper.vm.selectedFiles).toEqual(mockFiles);
    });
  });

  describe('modal management', () => {
    it('closes upload modal and resets data', () => {
      wrapper.setData({
        showUploadModal: true,
        selectedFile: new File(['test'], 'test.png'),
        previewUrl: 'blob:test-url',
        stickerTags: 'test',
        validationResult: { valid: true },
      });

      wrapper.vm.closeUploadModal();

      expect(wrapper.vm.showUploadModal).toBe(false);
      expect(wrapper.vm.selectedFile).toBe(null);
      expect(wrapper.vm.previewUrl).toBe(null);
      expect(wrapper.vm.stickerTags).toBe('');
      expect(wrapper.vm.validationResult).toBe(null);
    });

    it('closes bulk upload modal and resets data', () => {
      wrapper.setData({
        showBulkUploadModal: true,
        selectedFiles: [new File(['test'], 'test.png')],
        bulkUploadProgress: [{ filename: 'test.png', status: 'success' }],
      });

      wrapper.vm.closeBulkUploadModal();

      expect(wrapper.vm.showBulkUploadModal).toBe(false);
      expect(wrapper.vm.selectedFiles).toEqual([]);
      expect(wrapper.vm.bulkUploadProgress).toEqual([]);
    });
  });
});
