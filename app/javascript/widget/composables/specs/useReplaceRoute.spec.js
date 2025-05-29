import { useRoute, useRouter } from 'vue-router';
import { useReplaceRoute } from '../useReplaceRoute';

vi.mock('vue-router', () => ({
  useRoute: vi.fn(),
  useRouter: vi.fn(),
}));

describe('useReplaceRoute', () => {
  let mockRouter;
  let mockRoute;

  beforeEach(() => {
    vi.clearAllMocks();

    mockRouter = {
      replace: vi.fn().mockResolvedValue(undefined),
    };

    mockRoute = {
      name: 'current-route',
    };

    useRouter.mockReturnValue(mockRouter);
    useRoute.mockReturnValue(mockRoute);
  });

  it('should return replaceRoute function', () => {
    const { replaceRoute } = useReplaceRoute();

    expect(replaceRoute).toBeDefined();
    expect(typeof replaceRoute).toBe('function');
  });

  it('should replace route when target route is different from current', async () => {
    const { replaceRoute } = useReplaceRoute();

    await replaceRoute('home');

    expect(mockRouter.replace).toHaveBeenCalledTimes(1);
    expect(mockRouter.replace).toHaveBeenCalledWith({
      name: 'home',
      params: {},
    });
  });

  it('should pass params when replacing route', async () => {
    const { replaceRoute } = useReplaceRoute();
    const params = { id: '123', category: 'products' };

    await replaceRoute('product-detail', params);

    expect(mockRouter.replace).toHaveBeenCalledWith({
      name: 'product-detail',
      params,
    });
  });

  it('should not replace route when target route is same as current', async () => {
    const { replaceRoute } = useReplaceRoute();

    const result = await replaceRoute('current-route');

    expect(mockRouter.replace).not.toHaveBeenCalled();
    expect(result).toBeUndefined();
  });

  it('should not replace route when target route with params is same as current', async () => {
    const { replaceRoute } = useReplaceRoute();

    const result = await replaceRoute('current-route', { id: '456' });

    expect(mockRouter.replace).not.toHaveBeenCalled();
    expect(result).toBeUndefined();
  });

  it('should return router.replace result when navigation occurs', async () => {
    const navigationResult = { type: 'navigation-success' };
    mockRouter.replace.mockResolvedValue(navigationResult);

    const { replaceRoute } = useReplaceRoute();
    const result = await replaceRoute('about');

    expect(result).toBe(navigationResult);
  });

  it('should handle navigation failures', async () => {
    const navigationError = new Error('Navigation failed');
    mockRouter.replace.mockRejectedValue(navigationError);

    const { replaceRoute } = useReplaceRoute();

    await expect(replaceRoute('error-route')).rejects.toThrow(
      'Navigation failed'
    );
  });

  it('should handle undefined route names', async () => {
    mockRoute.name = undefined;

    const { replaceRoute } = useReplaceRoute();
    await replaceRoute('home');

    expect(mockRouter.replace).toHaveBeenCalledWith({
      name: 'home',
      params: {},
    });
  });

  it('should handle null route names', async () => {
    mockRoute.name = null;

    const { replaceRoute } = useReplaceRoute();
    await replaceRoute('home');

    expect(mockRouter.replace).toHaveBeenCalledWith({
      name: 'home',
      params: {},
    });
  });
});
