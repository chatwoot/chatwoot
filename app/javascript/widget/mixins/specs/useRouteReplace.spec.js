import { describe, it, expect, vi, beforeEach } from 'vitest';
import { useReplaceRoute } from 'widget/composables/useReplaceRoute';

const mockReplace = vi.fn();
const mockRoute = { name: 'initialRoute' };

vi.mock('dashboard/composables/route', () => ({
  useRouter: () => ({
    replace: mockReplace,
  }),
  useRoute: () => mockRoute,
}));

describe('useReplaceRoute', () => {
  let replaceRoute;

  beforeEach(() => {
    vi.clearAllMocks();
    mockRoute.name = 'initialRoute';
    replaceRoute = useReplaceRoute();
  });

  it('should replace route when current route is different', async () => {
    mockReplace.mockResolvedValue(undefined);

    await replaceRoute('newRoute', { id: 1 });

    expect(mockReplace).toHaveBeenCalledWith({
      name: 'newRoute',
      params: { id: 1 },
    });
  });

  it('should not replace route when current route is the same', async () => {
    mockRoute.name = 'sameRoute';

    const result = await replaceRoute('sameRoute');

    expect(mockReplace).not.toHaveBeenCalled();
    expect(result).toBeUndefined();
  });

  it('should handle router replace rejection', async () => {
    const error = new Error('Navigation aborted');
    mockReplace.mockRejectedValue(error);

    await expect(replaceRoute('newRoute')).rejects.toThrow(
      'Navigation aborted'
    );
  });
});
