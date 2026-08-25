import { deleteDB, openDB } from 'idb';
import { DataManager } from 'dashboard/helper/CacheHelper/DataManager';
import {
  deleteIndexedDBOnLogout,
  getLoadingStatus,
  parseAPIErrorResponse,
  setLoadingStatus,
  throwErrorMessage,
  parseLinearAPIErrorResponse,
} from '../api';

describe('#getLoadingStatus', () => {
  it('returns correct status', () => {
    expect(getLoadingStatus({ fetchAPIloadingStatus: true })).toBe(true);
  });
});

describe('#setLoadingStatus', () => {
  it('set correct status', () => {
    const state = { fetchAPIloadingStatus: true };
    setLoadingStatus(state, false);
    expect(state.fetchAPIloadingStatus).toBe(false);
  });
});

describe('#parseAPIErrorResponse', () => {
  it('returns correct values', () => {
    expect(
      parseAPIErrorResponse({
        response: { data: { message: 'Error Message [message]' } },
      })
    ).toBe('Error Message [message]');

    expect(
      parseAPIErrorResponse({
        response: { data: { error: 'Error Message [error]' } },
      })
    ).toBe('Error Message [error]');

    expect(parseAPIErrorResponse('Error: 422 Failed')).toBe(
      'Error: 422 Failed'
    );
  });
});

describe('#throwErrorMessage', () => {
  it('throws correct error', () => {
    const errorFn = function throwErrorMessageFn() {
      throwErrorMessage({
        response: { data: { message: 'Error Message [message]' } },
      });
    };
    expect(errorFn).toThrow('Error Message [message]');
  });
});

describe('#parseLinearAPIErrorResponse', () => {
  it('returns correct values', () => {
    expect(
      parseLinearAPIErrorResponse(
        {
          response: {
            data: {
              error: {
                errors: [
                  {
                    message: 'Error Message [message]',
                  },
                ],
              },
            },
          },
        },
        'Default Message'
      )
    ).toBe('Error Message [message]');
  });
});

describe('#deleteIndexedDBOnLogout', () => {
  const accountId = 'logout-test';
  const cacheDatabaseName = `cw-store-${accountId}`;
  const unrelatedDatabaseName = 'unrelated-database';
  let dataManager;
  let unrelatedDatabase;
  let blockingDatabase;

  afterEach(async () => {
    dataManager?.db?.close();
    unrelatedDatabase?.close();
    blockingDatabase?.close();
    await Promise.all([
      deleteDB(cacheDatabaseName),
      deleteDB(unrelatedDatabaseName),
    ]);
    localStorage.removeItem('cw-idb-names');
  });

  it('waits for active cache connections to close before deleting the database', async () => {
    dataManager = new DataManager(accountId);
    await dataManager.initDb();

    await deleteIndexedDBOnLogout();

    const databaseNames = (await indexedDB.databases()).map(({ name }) => name);
    expect(databaseNames).not.toContain(cacheDatabaseName);
  });

  it('preserves IndexedDB databases that are not owned by Chatwoot', async () => {
    unrelatedDatabase = await openDB(unrelatedDatabaseName, 1, {
      upgrade(database) {
        database.createObjectStore('sentinel');
      },
    });
    unrelatedDatabase.close();

    await deleteIndexedDBOnLogout();

    unrelatedDatabase = await openDB(unrelatedDatabaseName);
    expect([...unrelatedDatabase.objectStoreNames]).toContain('sentinel');
  });

  it('deletes tracked cache databases when database enumeration is unavailable', async () => {
    dataManager = new DataManager(accountId);
    await dataManager.initDb();
    const databasesSpy = vi
      .spyOn(indexedDB, 'databases')
      .mockRejectedValueOnce(new Error('Database enumeration unavailable'));

    await deleteIndexedDBOnLogout();
    databasesSpy.mockRestore();

    const databaseNames = (await indexedDB.databases()).map(({ name }) => name);
    expect(databaseNames).not.toContain(cacheDatabaseName);
  });

  it('continues logout and retains tracking when deletion is blocked', async () => {
    blockingDatabase = await openDB(cacheDatabaseName);
    localStorage.setItem('cw-idb-names', JSON.stringify([cacheDatabaseName]));

    await deleteIndexedDBOnLogout();

    expect(JSON.parse(localStorage.getItem('cw-idb-names'))).toContain(
      cacheDatabaseName
    );
  });
});
