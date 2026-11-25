# frozen_string_literal: true

# Specs never need the real Vite bundle. Rendering a view that calls the Vite
# tag helpers (e.g. the super_admin/Administrate layout) would otherwise trigger
# an on-demand `vite build` whenever no manifest exists (as in CI), which is
# slow enough to time out the request and surface as a 500. Stub the helpers so
# request specs render those layouts without building any assets.
ViteRails::TagHelpers.module_eval do
  def vite_client_tag(*_args, **_options) = ''
  def vite_javascript_tag(*_names, **_options) = ''
  def vite_typescript_tag(*_names, **_options) = ''
  def vite_stylesheet_tag(*_names, **_options) = ''
  def vite_react_refresh_tag(*_args, **_options) = ''
end
