import { describe, it, expect, beforeEach, vi } from 'vitest';
import { useImpersonation } from '../useImpersonation';

vi.mock('shared/helpers/sessionStorage', () => ({
  __esModule: true,
  default: {
    get: vi.fn(),
    set: vi.fn(),
  },
}));

import SessionStorage from 'shared/helpers/sessionStorage';
import { SESSION_STORAGE_KEYS } from 'dashboard/constants/sessionStorage';

describe('useImpersonation', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should return true if impersonation flag is set in session storage', () => {
    SessionStorage.get.mockReturnValue(true);
    const { isImpersonating } = useImpersonation();
    expect(isImpersonating.value).toBe(true);
    expect(SessionStorage.get).toHaveBeenCalledWith(
      SESSION_STORAGE_KEYS.IMPERSONATION_USER
    );
  });

  it('should return false if impersonation flag is not set in session storage', () => {
    SessionStorage.get.mockReturnValue(false);
    const { isImpersonating } = useImpersonation();
    expect(isImpersonating.value).toBe(false);
    expect(SessionStorage.get).toHaveBeenCalledWith(
      SESSION_STORAGE_KEYS.IMPERSONATION_USER
    );
  });
});
