import { initializeInstagramLoginSettings } from './instagramLoginSettings';

describe('Instagram login settings', () => {
  it('shows the chosen credentials and excludes hidden credentials from saves without clearing them', () => {
    document.body.innerHTML = `
      <form>
        <select id="app_config_INSTAGRAM_LOGIN_METHOD">
          <option value="instagram_login">Instagram Login</option>
          <option value="unified_login">Unified Login</option>
        </select>
        <div data-instagram-login-method="instagram_login">
          <fieldset><input name="legacy_secret" value="legacy"></fieldset>
        </div>
        <div data-instagram-login-method="unified_login">
          <fieldset><input name="unified_secret" value="unified"></fieldset>
        </div>
      </form>`;
    initializeInstagramLoginSettings();
    const form = document.querySelector('form');
    const select = document.querySelector('select');
    const legacy = document.querySelector(
      '[data-instagram-login-method="instagram_login"]'
    );
    const unified = document.querySelector(
      '[data-instagram-login-method="unified_login"]'
    );

    expect(new FormData(form).get('legacy_secret')).toBe('legacy');
    expect(new FormData(form).has('unified_secret')).toBe(false);
    select.value = 'unified_login';
    select.dispatchEvent(new Event('change'));
    expect(legacy.classList.contains('hidden')).toBe(true);
    expect(unified.classList.contains('hidden')).toBe(false);
    expect(new FormData(form).has('legacy_secret')).toBe(false);
    expect(new FormData(form).get('unified_secret')).toBe('unified');

    select.value = 'instagram_login';
    select.dispatchEvent(new Event('change'));
    expect(new FormData(form).get('legacy_secret')).toBe('legacy');
    expect(new FormData(form).has('unified_secret')).toBe(false);
  });
});
