import { describe, it, expect, vi, beforeEach } from 'vitest';
import { useReplaceRoute } from '../../composables/useReplaceRoute';

const mockRouter = {
  currentRoute: { name: 'initialRoute' },
  replace: vi.fn(),
};

vi.mock('../../composables/useReplaceRoute', () => ({
  useReplaceRoute: () => ({
    replaceRoute: async (name, params = {}) => {
      if (mockRouter.currentRoute.name !== name) {
        return mockRouter.replace({ name, params });
      }
      return undefined;
    },
  }),
}));

describe('useReplaceRoute', () => {
  let routerHelper;

  beforeEach(() => {
    vi.resetAllMocks();
    mockRouter.currentRoute = { name: 'initialRoute' };
    routerHelper = useReplaceRoute();
  });

  describe('replaceRoute', () => {
    it('should replace route when current route is different', async () => {
      mockRouter.replace.mockResolvedValue(undefined);

      await routerHelper.replaceRoute('newRoute', { id: 1 });

      expect(mockRouter.replace).toHaveBeenCalledWith({
        name: 'newRoute',
        params: { id: 1 },
      });
    });

    it('should not replace route when current route is the same', async () => {
      mockRouter.currentRoute.name = 'sameRoute';

      const result = await routerHelper.replaceRoute('sameRoute');

      expect(mockRouter.replace).not.toHaveBeenCalled();
      expect(result).toBeUndefined();
    });

    it('should handle router replace rejection', async () => {
      const error = new Error('Navigation aborted');
      mockRouter.replace.mockRejectedValue(error);

      await expect(routerHelper.replaceRoute('newRoute')).rejects.toThrow(
        'Navigation aborted'
      );
    });
  });
});
