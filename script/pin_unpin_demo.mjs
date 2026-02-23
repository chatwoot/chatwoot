import fs from 'node:fs/promises';
import path from 'node:path';
import { chromium } from 'playwright';

const BASE_URL = process.env.CHATWOOT_BASE_URL || 'http://localhost:3000';
const OUT_DIR = process.env.OUT_DIR || path.join('tmp', 'pin-demo');

const EMAIL = process.env.CHATWOOT_EMAIL || 'john@acme.inc';
const PASSWORD = process.env.CHATWOOT_PASSWORD || 'Password1!';
const CONVERSATION_URL =
  process.env.CONVERSATION_URL ||
  `${BASE_URL}/app/accounts/1/conversations/1`;

async function ensureDir(dir) {
  await fs.mkdir(dir, { recursive: true });
}

async function screenshot(page, filename) {
  const outPath = path.join(OUT_DIR, filename);
  await page.screenshot({ path: outPath, fullPage: true });
  // eslint-disable-next-line no-console
  console.log(`screenshot: ${outPath}`);
}

async function login(page) {
  await page.goto(`${BASE_URL}/app/login?pp=disable`, {
    waitUntil: 'domcontentloaded',
    timeout: 120000,
  });

  // Debug: capture what we got at /app/login in headless mode.
  // eslint-disable-next-line no-console
  console.log(`login url: ${page.url()}`);
  // eslint-disable-next-line no-console
  console.log(`login title: ${(await page.title().catch(() => '')) || ''}`);
  await page.waitForTimeout(1000);
  await screenshot(page, '00-login-page.png');

  const emailInput = page
    .locator(
      [
        'input[type="email"]',
        'input[name="email"]',
        'input[autocomplete="email"]',
      ].join(',')
    )
    .or(page.getByPlaceholder(/example@|email/i))
    .first();

  const passwordInput = page
    .locator(['input[type="password"]', 'input[name="password"]'].join(','))
    .or(page.getByPlaceholder(/password/i))
    .first();

  await emailInput.waitFor({ state: 'visible', timeout: 30000 });
  await passwordInput.waitFor({ state: 'visible', timeout: 30000 });

  await emailInput.fill(EMAIL);
  await passwordInput.fill(PASSWORD);

  const signInButton = page
    .getByRole('button', { name: /sign in|login/i })
    .first();
  await Promise.all([
    page.waitForNavigation({ waitUntil: 'domcontentloaded' }).catch(() => null),
    signInButton.click(),
  ]);
}

async function findPinnedBanner(page) {
  // Find the closest container around the "Pinned Message" label that also contains a button.
  // Using "closest" avoids matching large ancestor containers in the sidebar/header.
  const label = page.getByText('Pinned Message', { exact: true }).first();
  await label.waitFor({ state: 'visible', timeout: 60000 });
  return label.locator('xpath=ancestor::div[.//button][1]');
}

async function rightClickPinMessage(page) {
  // Try to pin a message via context menu.
  // Prefer a message content that exists in the seeded conversation.
  const candidateTexts = ['location', 'Hello'];
  let messageNode = null;

  for (const text of candidateTexts) {
    const node = page.getByText(text, { exact: true }).first();
    if ((await node.count()) > 0) {
      messageNode = node;
      break;
    }
  }

  if (!messageNode) return false;

  await messageNode.scrollIntoViewIfNeeded();
  await messageNode.click({ button: 'right' });

  const pinMenuItem = page.getByText(/^Pin$/).first();
  if ((await pinMenuItem.count()) === 0) return false;

  await pinMenuItem.click();
  return true;
}

async function main() {
  await ensureDir(OUT_DIR);

  const browser = await chromium.launch({
    headless: true,
  });
  const context = await browser.newContext();
  const page = await context.newPage();
  page.setDefaultTimeout(60000);
  page.setDefaultNavigationTimeout(120000);

  page.on('console', msg => {
    if (msg.type() === 'error') {
      // eslint-disable-next-line no-console
      console.error(`[browser console error] ${msg.text()}`);
    }
  });
  page.on('pageerror', err => {
    // eslint-disable-next-line no-console
    console.error(`[pageerror] ${err.stack || err.message}`);
  });
  page.on('response', res => {
    const status = res.status();
    const url = res.url();
    if (status >= 500) {
      // eslint-disable-next-line no-console
      console.error(`[http ${status}] ${url}`);
    }
  });
  let notFoundCount = 0;
  page.on('requestfinished', async request => {
    try {
      const response = request.response();
      if (!response) return;
      if (response.status() === 404 && notFoundCount < 10) {
        notFoundCount += 1;
        // eslint-disable-next-line no-console
        console.error(`[http 404] ${request.url()}`);
      }
    } catch {
      // ignore
    }
  });

  try {
    await login(page);

    const conversationUrl =
      CONVERSATION_URL.includes('?') ? `${CONVERSATION_URL}&pp=disable` : `${CONVERSATION_URL}?pp=disable`;
    await page.goto(conversationUrl, {
      waitUntil: 'domcontentloaded',
      timeout: 120000,
    });
    // Give the SPA time to fetch messages and render pinned banner.
    await page.waitForTimeout(12000);

    // If messages pane is still empty, try clicking the conversation in the list.
    const janeRow = page.getByText('Jane', { exact: true }).first();
    if ((await janeRow.count()) > 0) {
      await janeRow.click({ timeout: 5000 }).catch(() => null);
      await page.waitForTimeout(5000);
    }

    // Expect pinned banner to be visible if API pinned message already.
    const banner = await findPinnedBanner(page);
    if ((await banner.count()) > 0) {
      await screenshot(page, '01-conversation-pinned.png');

      await banner.locator('button').first().click();
      await page.getByText('Pinned Message').first().waitFor({
        state: 'detached',
        timeout: 15000,
      });
      await page.waitForTimeout(1000);
      await screenshot(page, '02-conversation-unpinned.png');
    } else {
      await screenshot(page, '01-conversation-no-banner.png');
    }

    // Try to pin again via UI context menu (right click → Pin).
    const didPin = await rightClickPinMessage(page);
    if (didPin) {
      await page.waitForTimeout(1500);
      await screenshot(page, '03-after-pin.png');
    } else {
      await screenshot(page, '03-could-not-pin-via-ui.png');
    }
  } finally {
    await context.close();
    await browser.close();
  }
}

main().catch(err => {
  // eslint-disable-next-line no-console
  console.error(err);
  process.exitCode = 1;
});

