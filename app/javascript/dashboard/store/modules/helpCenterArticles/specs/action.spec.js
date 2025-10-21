import axios from 'axios';
import { uploadExternalImage, uploadFile } from 'dashboard/helper/uploadHelper';
import * as types from '../../../mutation-types';
import { actions } from '../actions';

vi.mock('dashboard/helper/uploadHelper');

const articleList = [
  {
    id: 1,
    category_id: 1,
    title: 'Documents are required to complete KYC',
  },
];

const camelCasedArticle = {
  id: 1,
  categoryId: 1,
  title: 'Documents are required to complete KYC',
};

const commit = vi.fn();
const dispatch = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  describe('#index', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({
        data: {
          payload: articleList,
          meta: {
            current_page: '1',
            articles_count: 5,
          },
        },
      });
      await actions.index(
        { commit },
        { pageNumber: 1, portalSlug: 'test', locale: 'en' }
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_UI_FLAG, { isFetching: true }],
        [types.default.CLEAR_ARTICLES],
        [
          types.default.ADD_MANY_ARTICLES,
          [
            {
              id: 1,
              categoryId: 1,
              title: 'Documents are required to complete KYC',
            },
          ],
        ],
        [
          types.default.SET_ARTICLES_META,
          { currentPage: '1', articlesCount: 5 },
        ],
        [types.default.ADD_MANY_ARTICLES_ID, [1]],
        [types.default.SET_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.index(
          { commit },
          { pageNumber: 1, portalSlug: 'test', locale: 'en' }
        )
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_UI_FLAG, { isFetching: true }],
        [types.default.SET_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: { payload: camelCasedArticle } });
      await actions.create({ commit, dispatch }, camelCasedArticle);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_UI_FLAG, { isCreating: true }],
        [types.default.ADD_ARTICLE, camelCasedArticle],
        [types.default.ADD_ARTICLE_ID, 1],
        [types.default.ADD_ARTICLE_FLAG, 1],
        [types.default.SET_UI_FLAG, { isCreating: false }],
      ]);
    });

    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.create({ commit }, articleList[0])).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_UI_FLAG, { isCreating: true }],
        [types.default.SET_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      axios.patch.mockResolvedValue({ data: { payload: camelCasedArticle } });
      await actions.update(
        { commit },
        {
          portalSlug: 'room-rental',
          articleId: 1,
          title: 'Documents are required to complete KYC',
        }
      );
      expect(commit.mock.calls).toEqual([
        [
          types.default.UPDATE_ARTICLE_FLAG,
          { uiFlags: { isUpdating: true }, articleId: 1 },
        ],
        [types.default.UPDATE_ARTICLE, camelCasedArticle],
        [
          types.default.UPDATE_ARTICLE_FLAG,
          { uiFlags: { isUpdating: false }, articleId: 1 },
        ],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.update(
          { commit },
          {
            portalSlug: 'room-rental',
            articleId: 1,
            title: 'Documents are required to complete KYC',
          }
        )
      ).rejects.toThrow(Error);

      expect(commit.mock.calls).toEqual([
        [
          types.default.UPDATE_ARTICLE_FLAG,
          { uiFlags: { isUpdating: true }, articleId: 1 },
        ],
        [
          types.default.UPDATE_ARTICLE_FLAG,
          { uiFlags: { isUpdating: false }, articleId: 1 },
        ],
      ]);
    });
  });

  describe('#updateArticleMeta', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({
        data: {
          payload: articleList,
          meta: {
            all_articles_count: 56,
            archived_articles_count: 7,
            articles_count: 56,
            current_page: '1', // This is not needed, it cause pagination issues.
            draft_articles_count: 24,
            mine_articles_count: 44,
            published_count: 25,
          },
        },
      });
      await actions.updateArticleMeta(
        { commit },
        { pageNumber: 1, portalSlug: 'test', locale: 'en' }
      );
      expect(commit.mock.calls).toEqual([
        [
          types.default.SET_ARTICLES_META,
          {
            allArticlesCount: 56,
            archivedArticlesCount: 7,
            articlesCount: 56,
            draftArticlesCount: 24,
            mineArticlesCount: 44,
            publishedCount: 25,
          },
        ],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({ data: articleList[0] });
      await actions.delete(
        { commit },
        { portalSlug: 'test', articleId: articleList[0].id }
      );

      expect(commit.mock.calls).toEqual([
        [
          types.default.UPDATE_ARTICLE_FLAG,
          { uiFlags: { isDeleting: true }, articleId: 1 },
        ],
        [types.default.REMOVE_ARTICLE, articleList[0].id],
        [types.default.REMOVE_ARTICLE_ID, articleList[0].id],
        [
          types.default.UPDATE_ARTICLE_FLAG,
          { uiFlags: { isDeleting: false }, articleId: 1 },
        ],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.delete(
          { commit },
          { portalSlug: 'test', articleId: articleList[0].id }
        )
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [
          types.default.UPDATE_ARTICLE_FLAG,
          { uiFlags: { isDeleting: true }, articleId: 1 },
        ],
        [
          types.default.UPDATE_ARTICLE_FLAG,
          { uiFlags: { isDeleting: false }, articleId: 1 },
        ],
      ]);
    });
  });

  describe('attachImage', () => {
    it('should upload the file and return the fileUrl', async () => {
      const mockFile = new Blob(['test'], { type: 'image/png' });
      mockFile.name = 'test.png';

      const mockFileUrl = 'https://test.com/test.png';
      uploadFile.mockResolvedValueOnce({ fileUrl: mockFileUrl });

      const result = await actions.attachImage({}, { file: mockFile });

      expect(uploadFile).toHaveBeenCalledWith(mockFile);
      expect(result).toBe(mockFileUrl);
    });

    it('should throw an error if the upload fails', async () => {
      const mockFile = new Blob(['test'], { type: 'image/png' });
      mockFile.name = 'test.png';

      const mockError = new Error('Upload failed');
      uploadFile.mockRejectedValueOnce(mockError);

      await expect(actions.attachImage({}, { file: mockFile })).rejects.toThrow(
        'Upload failed'
      );
    });
  });

  describe('uploadExternalImage', () => {
    it('should upload the image from external URL and return the fileUrl', async () => {
      const mockUrl = 'https://example.com/image.jpg';
      const mockFileUrl = 'https://uploaded.example.com/image.jpg';
      uploadExternalImage.mockResolvedValueOnce({ fileUrl: mockFileUrl });

      // When
      const result = await actions.uploadExternalImage({}, { url: mockUrl });

      // Then
      expect(uploadExternalImage).toHaveBeenCalledWith(mockUrl);
      expect(result).toBe(mockFileUrl);
    });

    it('should throw an error if the upload fails', async () => {
      const mockUrl = 'https://example.com/image.jpg';
      const mockError = new Error('Upload failed');
      uploadExternalImage.mockRejectedValueOnce(mockError);

      await expect(
        actions.uploadExternalImage({}, { url: mockUrl })
      ).rejects.toThrow('Upload failed');
    });
  });
});
