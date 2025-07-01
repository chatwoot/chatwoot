document.addEventListener('DOMContentLoaded', function() {
  const form = document.getElementById('new_email_template');
  if (!form) return;

  const slugInput = form.querySelector('#email_template_slug');
  const accountSelect = form.querySelector('#email_template_account_id');

  async function checkSlugInbox() {
    const slug = slugInput.value;
    const accountId = accountSelect.value;
    if (!slug) return false;

    const response = await fetch(`/super_admin/email_templates/check_slug_inbox?slug=${encodeURIComponent(slug)}&account_id=${encodeURIComponent(accountId)}`,);
    const data = await response.json();
    return data.exists;
  }

  form.addEventListener('submit', async function(e) {
    e.preventDefault();
    const exists = await checkSlugInbox();
    if (exists) {
      if (confirm('A template with this slug already exists for the selected account. The previous one will be replaced. Continue?')) {
        form.submit();
      }
    } else {
      form.submit();
    }
  });
});