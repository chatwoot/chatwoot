# Fork task (net-new file — no upstream overlap, so upstream merges never conflict).
# Thin shim over the fork-owned Custom::SuperAdminBootstrap service; the logic +
# tests live in custom/ and spec/custom/. See docs/fork/SUPER_ADMIN.md §4.
#
#   bundle exec rails fork:super_admin:bootstrap
#
# Idempotent — wire it into the boot/deploy sequence (before `rails server`) so a
# fresh instance comes up with a real operator instead of the dev seed.
namespace :fork do
  namespace :super_admin do
    desc 'Provision the platform Super Admin from env + apply baseline hardening (idempotent)'
    task bootstrap: :environment do
      Custom::SuperAdminBootstrap.run
    end
  end
end
