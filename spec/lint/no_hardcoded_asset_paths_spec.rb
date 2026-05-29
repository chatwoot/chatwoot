# frozen_string_literal: true

require 'rails_helper'

# Regression test for issue #13687 + adjacent CDN-asset-URL leaks.
#
# Greps app/, lib/, enterprise/ for literal asset paths (e.g. '/assets/foo.png',
# '/audio/dashboard/ding.mp3', '/packs/js/sdk.js') that would bypass
# ASSET_CDN_HOST. Files containing such paths must either:
#   (a) be patched to wrap each path in a helper (image_tag / asset_url /
#       Cdn.asset_url / useAssetUrl) and added to ALLOWLIST, OR
#   (b) be a static config / seed / the regression test itself.
#
# Adding a file to ALLOWLIST is an audit declaration — reviewers should
# confirm every literal asset path in the file flows through a CDN helper.
# rubocop:disable RSpec/DescribeClass
RSpec.describe 'no hardcoded asset paths' do
  # Match only paths that are unambiguously *asset* paths.
  # - /assets, /audio, /brand-assets, /packs are always served from public/
  # - /dashboard and /integrations are also Rails route/API prefixes, so we
  #   require an additional /images or extension to confirm it's an asset.
  # - root-level fingerprinted PNG/ICOs and PWA files
  # rubocop:disable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration
  ASSET_PREFIX = %r{
    /(?:
      (?:assets|audio|brand-assets|packs)/ |
      dashboard/images/ |
      integrations/[a-z0-9_-]+(?:/[a-z0-9_.-]+)?\.(?:png|svg|jpg|jpeg|gif|webp) |
      favicon-[a-z0-9-]+\.[a-z]+ |
      favicon\.ico |
      apple-icon[a-z0-9-]*\.[a-z]+ |
      android-icon-[a-z0-9-]+\.[a-z]+ |
      ms-icon-[a-z0-9-]+\.[a-z]+ |
      manifest\.json |
      browserconfig\.xml
    )
  }x

  # ASSET_PREFIX is built with /x (extended mode) for readability. Its `.source`
  # therefore contains literal whitespace which would be matched as-is if
  # interpolated into a non-extended regex literal. Building each PROHIBITED
  # branch via Regexp.new(..., Regexp::EXTENDED) preserves the /x semantics.
  PROHIBITED = Regexp.union(
    Regexp.new("[\"'`]#{ASSET_PREFIX.source}", Regexp::EXTENDED),
    Regexp.new("\\#\\{[^}]*(?:FRONTEND_URL|base_url|BASE_URL)[^}]*\\}#{ASSET_PREFIX.source}", Regexp::EXTENDED),
    Regexp.new("\\$\\{[^}]*(?:baseUrl|BASE_URL)[^}]*\\}#{ASSET_PREFIX.source}", Regexp::EXTENDED)
  )

  ALLOWLIST = %w[
    lib/cdn.rb
    app/javascript/shared/composables/useAssetUrl.js
    app/javascript/shared/helpers/AudioNotificationHelper.js

    config/integration/apps.yml
    config/installation_config.yml
    enterprise/config/premium_installation_config.yml

    app/views/super_admin/application/_navigation.html.erb
    app/views/layouts/vueapp.html.erb
    app/views/installation/onboarding/index.html.erb
    app/views/super_admin/devise/sessions/new.html.erb
    app/views/widget_tests/index.html.erb
    app/views/super_admin/application/_javascript.html.erb
    app/views/public/api/v1/portals/_footer.html.erb
    app/views/public/api/v1/portals/documentation_layout/_footer.html.erb
    app/models/channel/web_widget.rb
    app/fields/avatar_field.rb
    app/controllers/slack_uploads_controller.rb
    lib/integrations/dyte/processor_service.rb
    enterprise/app/models/captain/assistant.rb

    app/javascript/widget/components/AgentMessage.vue
    app/javascript/widget/components/UnreadMessage.vue
    app/javascript/dashboard/components-next/Contacts/ContactsSidebar/components/ContactNoteItem.vue
    app/javascript/dashboard/components-next/call/FloatingCallWidget.vue
    app/javascript/dashboard/components-next/captain/pageComponents/emptyStates/AssistantPageEmptyState.vue
    app/javascript/dashboard/components-next/captain/pageComponents/emptyStates/ResponsePageEmptyState.vue
    app/javascript/dashboard/components-next/captain/pageComponents/emptyStates/CustomToolsPageEmptyState.vue
    app/javascript/dashboard/components-next/captain/pageComponents/emptyStates/DocumentPageEmptyState.vue
    app/javascript/dashboard/components-next/year-in-review/YearInReviewBanner.vue
    app/javascript/dashboard/components-next/year-in-review/YearInReviewModal.vue
    app/javascript/dashboard/components-next/year-in-review/ShareModal.vue
    app/javascript/dashboard/components-next/year-in-review/slides/BusiestDaySlide.vue
    app/javascript/dashboard/components-next/year-in-review/slides/ConversationsSlide.vue
    app/javascript/dashboard/components-next/year-in-review/slides/IntroSlide.vue
    app/javascript/dashboard/components-next/year-in-review/slides/PersonalitySlide.vue
    app/javascript/dashboard/components-next/year-in-review/slides/ThankYouSlide.vue
    app/javascript/dashboard/components/widgets/conversation/OnboardingView.vue
    app/javascript/dashboard/components/widgets/conversation/linear/LinearSetupCTA.vue
    app/javascript/dashboard/helper/AudioAlerts/DashboardAudioNotificationHelper.js
    app/javascript/dashboard/helper/AudioAlerts/faviconHelper.js
    app/javascript/dashboard/routes/dashboard/captain/assistants/Index.vue
    app/javascript/dashboard/routes/dashboard/captain/documents/Index.vue
    app/javascript/dashboard/routes/dashboard/captain/responses/Index.vue
    app/javascript/dashboard/routes/dashboard/captain/responses/Pending.vue
    app/javascript/dashboard/routes/dashboard/settings/integrations/Integration.vue
    app/javascript/dashboard/routes/dashboard/settings/integrations/IntegrationItem.vue
    app/javascript/dashboard/routes/dashboard/settings/integrations/SingleIntegrationHooks.vue
    app/javascript/dashboard/routes/dashboard/settings/profile/Index.vue
    app/javascript/dashboard/routes/dashboard/settings/profile/AudioAlertTone.vue
  ].to_set.freeze
  # rubocop:enable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration

  it 'no source file outside the audited allowlist contains literal asset paths' do
    rails_root = Rails.root.to_s
    leaks = []

    Dir.glob('{app,lib,enterprise}/**/*.{rb,erb,js,ts,vue,jsx,tsx,mjs,cjs}', base: rails_root).each do |path|
      next if ALLOWLIST.include?(path)
      next if path.match?(%r{/(?:spec|specs)/|\.spec\.|\.story\.vue})

      full_path = File.join(rails_root, path)
      File.foreach(full_path).with_index(1) do |line, lineno|
        leaks << "#{path}:#{lineno}: #{line.strip}" if PROHIBITED.match?(line)
      end
    end

    expect(leaks).to be_empty, lambda {
      <<~MSG
        Hardcoded asset paths found that bypass ASSET_CDN_HOST. If these are
        intentional (wrapped in image_tag / asset_url / Cdn.asset_url / useAssetUrl),
        add the file to ALLOWLIST in this spec. Otherwise wrap the path in the
        appropriate helper.

        #{leaks.join("\n")}
      MSG
    }
  end
end
# rubocop:enable RSpec/DescribeClass
