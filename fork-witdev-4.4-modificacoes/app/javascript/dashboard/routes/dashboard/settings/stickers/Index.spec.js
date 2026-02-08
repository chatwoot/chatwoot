import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import VueRouter from 'vue-router';
import StickerManagement from './Index.vue';

const localVue = createLocalVue();
localVue.use(Vuex);
localVue.use(VueRouter);

const router = new VueRouter();

describe('StickerManagement', () => {
  let store;
  let actions;
  let getters;
  let wrapper;

  const mockStickerPacks = [
    {
      name: 'Company Logos',
      sticker_count: 5,
      created_at: '2024-01-01T00:00:00Z',
    },
    {
      name: 'Emojis',
      sticker_count: 10,
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

    wrapper = mount(StickerManagement, {
      store,
      localVue,
      router,
      mocks: {
        $t: key => key,
        $http: {
          get: vi.fn(),
          post: vi.fn(),
          put: vi.fn(),
          delete: vi.fn(),
        },
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('component rendering', () => {
    it('renders the page title correctly', () => {
      expect(wrapper.find('.page-title').text()).toBe(
        'STICKER_MANAGEMENT.TITLE'
      );
    });

    it('renders create pack button', () => {
      const createButton = wrapper.find('[data-testid="create-pack-button"]');
      expect(createButton.exists()).toBe(true);
    });

    it('shows loading state when fetching data', async () => {
      wrapper.setData({ isLoading: true });
      await wrapper.vm.$nextTick();

      expect(wrapper.find('.loading-state').exists()).toBe(true);
      expect(wrapper.find('.loading-state').text()).toContain(
        'STICKER_MANAGEMENT.LOADING'
      );
    });

    it('shows empty state when no packs exist', async () => {
      wrapper.setData({ isLoading: false, stickerPacks: [] });
      await wrapper.vm.$nextTick();

      expect(wrapper.find('.empty-state').exists()).toBe(true);
      expect(wrapper.find('.empty-state h3').text()).toBe(
        'STICKER_MANAGEMENT.EMPTY_STATE.TITLE'
      );
    });

    it('renders sticker packs grid when packs exist', async () => {
      wrapper.setData({ isLoading: false, stickerPacks: mockStickerPacks });
      await wrapper.vm.$nextTick();

      expect(wrapper.find('.sticker-packs-grid').exists()).toBe(true);
      expect(wrapper.findAll('.sticker-pack-card')).toHaveLength(2);
    });
  });

  describe('API interactions', () => {
    it('fetches sticker packs on mount', () => {
      expect(wrapper.vm.$http.get).toHaveBeenCalledWith(
        '/api/v1/accounts/1/sticker_packs'
      );
    });

    it('handles fetch error gracefully', async () => {
      const consoleSpy = vi.spyOn(console, 'error').mockImplementation();
      wrapper.vm.$http.get.mockRejectedValue(new Error('Network error'));

      await wrapper.vm.fetchStickerPacks();

      expect(wrapper.vm.isLoading).toBe(false);
      consoleSpy.mockRestore();
    });
  });

  describe('pack management', () => {
    beforeEach(() => {
      wrapper.setData({ stickerPacks: mockStickerPacks });
    });

    it('opens create pack modal when create button is clicked', async () => {
      const createButton = wrapper.find('[data-testid="create-pack-button"]');
      await createButton.trigger('click');

      expect(wrapper.vm.showCreatePackModal).toBe(true);
    });

    it('opens pack details when pack card is clicked', async () => {
      const packCard = wrapper.find('.sticker-pack-card');
      await packCard.trigger('click');

      expect(wrapper.vm.$router.currentRoute.name).toBe('sticker_pack_details');
    });

    it('opens edit modal when edit button is clicked', async () => {
      const editButton = wrapper.find('[data-testid="edit-pack-button"]');
      await editButton.trigger('click');

      expect(wrapper.vm.showEditPackModal).toBe(true);
      expect(wrapper.vm.editingPack).toEqual(mockStickerPacks[0]);
    });

    it('opens delete modal when delete button is clicked', async () => {
      const deleteButton = wrapper.find('[data-testid="delete-pack-button"]');
      await deleteButton.trigger('click');

      expect(wrapper.vm.showDeleteModal).toBe(true);
      expect(wrapper.vm.deletingPack).toEqual(mockStickerPacks[0]);
    });
  });

  describe('create pack functionality', () => {
    it('creates a new pack successfully', async () => {
      wrapper.vm.$http.post.mockResolvedValue({
        data: { pack_name: 'New Pack' },
      });
      wrapper.setData({
        showCreatePackModal: true,
        newPackName: 'New Pack',
      });

      await wrapper.vm.createPack();

      expect(wrapper.vm.$http.post).toHaveBeenCalledWith(
        '/api/v1/accounts/1/sticker_packs',
        { sticker_pack: { name: 'New Pack' } }
      );
      expect(wrapper.vm.showCreatePackModal).toBe(false);
      expect(wrapper.vm.newPackName).toBe('');
    });

    it('handles create pack error', async () => {
      const error = { response: { data: { error: 'Pack already exists' } } };
      wrapper.vm.$http.post.mockRejectedValue(error);
      wrapper.setData({
        showCreatePackModal: true,
        newPackName: 'Existing Pack',
      });

      await wrapper.vm.createPack();

      expect(wrapper.vm.isCreatingPack).toBe(false);
    });

    it('does not create pack with empty name', async () => {
      wrapper.setData({
        showCreatePackModal: true,
        newPackName: '   ',
      });

      await wrapper.vm.createPack();

      expect(wrapper.vm.$http.post).not.toHaveBeenCalled();
    });
  });

  describe('update pack functionality', () => {
    beforeEach(() => {
      wrapper.setData({
        editingPack: mockStickerPacks[0],
        editingPackName: 'Updated Pack',
        showEditPackModal: true,
      });
    });

    it('updates pack name successfully', async () => {
      wrapper.vm.$http.put.mockResolvedValue({
        data: { old_name: 'Company Logos', new_name: 'Updated Pack' },
      });

      await wrapper.vm.updatePack();

      expect(wrapper.vm.$http.put).toHaveBeenCalledWith(
        '/api/v1/accounts/1/sticker_packs/Company Logos',
        { sticker_pack: { name: 'Updated Pack' } }
      );
      expect(wrapper.vm.showEditPackModal).toBe(false);
    });

    it('handles update pack error', async () => {
      const error = { response: { data: { error: 'Update failed' } } };
      wrapper.vm.$http.put.mockRejectedValue(error);

      await wrapper.vm.updatePack();

      expect(wrapper.vm.isUpdatingPack).toBe(false);
    });
  });

  describe('delete pack functionality', () => {
    beforeEach(() => {
      wrapper.setData({
        deletingPack: mockStickerPacks[0],
        showDeleteModal: true,
      });
    });

    it('deletes pack successfully', async () => {
      wrapper.vm.$http.delete.mockResolvedValue({
        data: { message: 'Pack deleted', deleted_stickers: 5 },
      });

      await wrapper.vm.confirmDeletePack();

      expect(wrapper.vm.$http.delete).toHaveBeenCalledWith(
        '/api/v1/accounts/1/sticker_packs/Company Logos'
      );
      expect(wrapper.vm.showDeleteModal).toBe(false);
    });

    it('handles delete pack error', async () => {
      const error = { response: { data: { error: 'Delete failed' } } };
      wrapper.vm.$http.delete.mockRejectedValue(error);

      await wrapper.vm.confirmDeletePack();

      // Should still be in delete modal state on error
      expect(wrapper.vm.showDeleteModal).toBe(true);
    });
  });

  describe('utility methods', () => {
    it('formats date correctly', () => {
      const dateString = '2024-01-01T00:00:00Z';
      const formatted = wrapper.vm.formatDate(dateString);

      expect(formatted).toBe(new Date(dateString).toLocaleDateString());
    });

    it('handles empty date string', () => {
      const formatted = wrapper.vm.formatDate('');
      expect(formatted).toBe('');
    });

    it('handles null date', () => {
      const formatted = wrapper.vm.formatDate(null);
      expect(formatted).toBe('');
    });
  });

  describe('modal management', () => {
    it('closes create pack modal and resets data', () => {
      wrapper.setData({
        showCreatePackModal: true,
        newPackName: 'Test Pack',
      });

      wrapper.vm.closeCreatePackModal();

      expect(wrapper.vm.showCreatePackModal).toBe(false);
      expect(wrapper.vm.newPackName).toBe('');
    });

    it('closes edit pack modal and resets data', () => {
      wrapper.setData({
        showEditPackModal: true,
        editingPack: mockStickerPacks[0],
        editingPackName: 'Test Pack',
      });

      wrapper.vm.closeEditPackModal();

      expect(wrapper.vm.showEditPackModal).toBe(false);
      expect(wrapper.vm.editingPack).toBe(null);
      expect(wrapper.vm.editingPackName).toBe('');
    });

    it('closes delete modal and resets data', () => {
      wrapper.setData({
        showDeleteModal: true,
        deletingPack: mockStickerPacks[0],
      });

      wrapper.vm.closeDeleteModal();

      expect(wrapper.vm.showDeleteModal).toBe(false);
      expect(wrapper.vm.deletingPack).toBe(null);
    });
  });
});
