import { Page } from '@playwright/test';

type DashboardApi = {
  delete: (url: string) => Promise<unknown>;
  get: (url: string) => Promise<{
    data: {
      payload: Array<{ id: number }>;
    };
  }>;
};

export class SettingsInboxPage {
  constructor(private page: Page) {}

  async navigate(accountId: number = 1) {
    await this.page.goto(`/app/accounts/${accountId}/settings/inboxes/list`);
  }

  getAddInboxButton() {
    return this.page.getByRole('link', { name: 'Add Inbox' });
  }

  async clickAddInboxButton() {
    await this.getAddInboxButton().click();
  }

  getPageHeading() {
    return this.page.getByRole('heading', { name: /inboxes/i });
  }

  async deleteInbox(accountId: number, inboxId: number) {
    await this.page.evaluate(
      async ({ accountId: currentAccountId, inboxId: currentInboxId }) => {
        const api = (window as typeof window & { axios: DashboardApi }).axios;
        await api.delete(
          `/api/v1/accounts/${currentAccountId}/inboxes/${currentInboxId}`
        );
      },
      { accountId, inboxId }
    );
  }

  async isInboxPresent(accountId: number, inboxId: number) {
    return this.page.evaluate(
      async ({ accountId: currentAccountId, inboxId: currentInboxId }) => {
        const api = (window as typeof window & { axios: DashboardApi }).axios;
        const response = await api.get(
          `/api/v1/accounts/${currentAccountId}/inboxes`
        );
        return response.data.payload.some(
          inbox => inbox.id === currentInboxId
        );
      },
      { accountId, inboxId }
    );
  }
}
