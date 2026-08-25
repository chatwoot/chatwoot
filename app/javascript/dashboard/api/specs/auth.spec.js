import AuthAPI from '../auth';

const { clearCookiesOnLogout, deleteIndexedDBOnLogout } = vi.hoisted(() => ({
  clearCookiesOnLogout: vi.fn(),
  deleteIndexedDBOnLogout: vi.fn(),
}));

vi.mock('dashboard/store/utils/api', async importOriginal => ({
  ...(await importOriginal()),
  clearCookiesOnLogout,
  deleteIndexedDBOnLogout,
}));

describe('#AuthAPI', () => {
  const originalAxios = window.axios;
  const axiosMock = {
    delete: vi.fn(),
  };

  beforeEach(() => {
    window.axios = axiosMock;
  });

  afterEach(() => {
    window.axios = originalAxios;
  });

  it('waits for IndexedDB cleanup before clearing the browser session', async () => {
    let resolveCleanup;
    deleteIndexedDBOnLogout.mockReturnValue(
      new Promise(resolve => {
        resolveCleanup = resolve;
      })
    );
    axiosMock.delete.mockResolvedValue({ data: {} });

    const logoutPromise = AuthAPI.logout();
    await vi.waitFor(() => expect(deleteIndexedDBOnLogout).toHaveBeenCalled());

    expect(clearCookiesOnLogout).not.toHaveBeenCalled();

    resolveCleanup();
    await logoutPromise;

    expect(clearCookiesOnLogout).toHaveBeenCalledOnce();
  });
});
