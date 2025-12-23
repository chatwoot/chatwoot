# frozen_string_literal: true

class ViteRuby::CLI::SSR < ViteRuby::CLI::Vite
  DEFAULT_ENV = CURRENT_ENV || 'production'
  JS_EXTENSIONS = %w[js mjs cjs]

  desc 'Run the resulting app from building in SSR mode.'
  executable_options

  def call(mode:, inspect: false, trace_deprecation: false)
    ViteRuby.env['VITE_RUBY_MODE'] = mode

    ssr_entrypoint = JS_EXTENSIONS
      .map { |ext| ViteRuby.config.ssr_output_dir.join("ssr.#{ ext }") }
      .find(&:exist?)

    raise ArgumentError, "No ssr entrypoint found `#{ ViteRuby.config.ssr_output_dir.relative_path_from(ViteRuby.config.root) }/ssr.{#{ JS_EXTENSIONS.join(',') }}`. Have you run bin/vite build --ssr?" unless ssr_entrypoint

    cmd = [
      'node',
      ('--inspect-brk' if inspect),
      ('--trace-deprecation' if trace_deprecation),
      ssr_entrypoint,
    ]
    Kernel.exec(*cmd.compact.map(&:to_s))
  end
end
