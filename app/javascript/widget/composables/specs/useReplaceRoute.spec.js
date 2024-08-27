import { describe, it, expect, vi } from 'vitest';
import { useReplaceRoute } from '../useReplaceRoute';

vi.mock('dashboard/composables/route', () => ({
  useRouter: vi.fn(),
  useRoute: vi.fn(),
}));

import { useRouter, useRoute } from 'dashboard/composables/route';

describe('useReplaceRoute', () => {
  const mockReplace = vi.fn();
  const mockRouter = { replace: mockReplace };

  beforeEach(() => {
    vi.clearAllMocks();
    useRouter.mockReturnValue(mockRouter);
  });

  it('should replace route when current route is different', () => {
    useRoute.mockReturnValue({ name: 'currentRoute' });
    const replaceRoute = useReplaceRoute();

    replaceRoute('newRoute', { id: 1 });

    expect(mockReplace).toHaveBeenCalledWith({
      name: 'newRoute',
      params: { id: 1 },
    });
  });

  it('should not replace route when current route is the same', () => {
    useRoute.mockReturnValue({ name: 'sameRoute' });
    const replaceRoute = useReplaceRoute();

    const result = replaceRoute('sameRoute');

    expect(mockReplace).not.toHaveBeenCalled();
    expect(result).toBeUndefined();
  });

  it('should return the result of router.replace when replacing route', () => {
    useRoute.mockReturnValue({ name: 'currentRoute' });
    mockReplace.mockReturnValue('replacementResult');
    const replaceRoute = useReplaceRoute();

    const result = replaceRoute('newRoute');

    expect(result).toBe('replacementResult');
  });
});
