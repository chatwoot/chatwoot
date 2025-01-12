import articleAPI from './api/articleAPI';
import { createResourceStore } from './piniaStoreFactory';

export const useArticleStore = createResourceStore('articles', {
  api: articleAPI,
});
