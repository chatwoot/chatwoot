#!/usr/bin/env ruby
# frozen_string_literal: true

# Guards the boundary between upstream's translations and the fork's.
#
#   ruby scripts/i18n/fork_translations.rb check
#   ruby scripts/i18n/fork_translations.rb drift [--base vX.Y.Z]
#   ruby scripts/i18n/fork_translations.rb scaffold es
#
# `check` needs nothing but the working tree. `drift` needs the upstream tag to
# be fetched first, which the CI workflow does explicitly since the fork's
# remote does not carry Chatwoot's tags.

require 'json'
require 'yaml'
require 'open3'
require 'fileutils'

# Each frontend bundle carries its own translations, so the fork has one overlay per
# bundle. They differ in layout: the dashboard ships a folder per language (one file per
# namespace), the survey a single file, since it is one small namespace.
FE_TREES = [
  { upstream: 'app/javascript/dashboard/i18n/locale', fork: 'app/javascript/dashboard/i18n/fazer-ai/locale', layout: :directory },
  { upstream: 'app/javascript/survey/i18n/locale', fork: 'app/javascript/survey/i18n/fazer-ai/locale', layout: :file }
].freeze
FE_UPSTREAM = FE_TREES.first[:upstream]
FE_FORK = FE_TREES.first[:fork]
BE_FORK_GLOB = 'config/locales/fazer_ai*.yml'
OVERRIDES = 'overrides.json'
REFERENCE_LOCALE = 'en'

# The Chatwoot release whose translations this fork currently carries.
# The sync-fork flow bumps it together with the upstream merge.
UPSTREAM_BASE = 'v4.20.1'

class ForkTranslations # rubocop:disable Metrics/ClassLength
  def initialize
    @errors = []
  end

  def check
    check_reference_locale_exists
    check_fork_files_have_no_duplicated_keys
    check_fork_keys_are_not_duplicated_upstream
    check_every_key_exists_in_reference
    check_reference_keys_are_translated_everywhere
    check_upstream_indexes_ignore_the_fork
    report_coverage
    finish
  end

  # Every upstream translation file must still match the tracked release.
  def drift(base)
    unless system("git rev-parse --verify --quiet #{base}^{commit} > /dev/null")
      abort "tag #{base} nao esta disponivel neste clone (git fetch --tags)"
    end

    changed = capture('git', 'diff', '--name-only', base, '--', *FE_TREES.map { |tree| tree[:upstream] }, 'config/locales')
              .split("\n")
              .reject { |path| File.fnmatch(BE_FORK_GLOB, path) }

    changed.each do |path|
      @errors << "#{path} diverge de #{base}: traducoes do fork vao em #{FE_FORK}/<locale>/ ou config/locales/fazer_ai.<locale>.yml"
    end
    finish
  end

  def scaffold(locale)
    abort 'informe o locale, ex: scaffold es' if locale.to_s.empty?
    abort "#{locale} ja existe em #{FE_FORK}" if Dir.exist?(File.join(FE_FORK, locale))

    FE_TREES.each { |tree| scaffold_tree(tree, locale) }
    scaffold_backend(locale)

    puts "traduza os valores; chaves nao traduzidas caem no fallback em #{REFERENCE_LOCALE}"
  end

  private

  def scaffold_tree(tree, locale)
    reference = tree_paths(tree[:fork], tree[:layout], REFERENCE_LOCALE)
    return puts("#{tree[:fork]} nao tem #{REFERENCE_LOCALE}; nada a copiar") if reference.empty?

    if tree[:layout] == :directory
      target = File.join(tree[:fork], locale)
      FileUtils.mkdir_p(target)
      reference.each { |path| FileUtils.cp(path, File.join(target, File.basename(path))) }
      puts "criado #{target}/ com #{reference.size} arquivos copiados de #{REFERENCE_LOCALE}"
    else
      target = File.join(tree[:fork], "#{locale}.json")
      FileUtils.cp(reference.first, target)
      puts "criado #{target} copiado de #{REFERENCE_LOCALE}"
    end
  end

  def scaffold_backend(locale)
    Dir["config/locales/fazer_ai*.#{REFERENCE_LOCALE}.yml"].each do |path|
      copy = path.sub(".#{REFERENCE_LOCALE}.yml", ".#{locale}.yml")
      tree = YAML.safe_load_file(path, aliases: true)
      body = { locale => tree.values.first }.to_yaml(line_width: -1).delete_prefix("---\n")
      File.write(copy, header(path) + body)
      puts "criado #{copy}"
    end
  end

  def capture(*)
    out, _err, status = Open3.capture3(*)
    status.success? ? out : ''
  end

  def header(path)
    File.readlines(path).take_while { |line| line.start_with?('#') }.join
  end

  def fork_locales
    @fork_locales ||= FE_TREES.flat_map { |tree| locales_in(tree) }.uniq.sort
  end

  def locales_in(tree)
    if tree[:layout] == :directory
      Dir["#{tree[:fork]}/*"].select { |path| File.directory?(path) }.map { |path| File.basename(path) }
    else
      Dir["#{tree[:fork]}/*.json"].map { |path| File.basename(path, '.json') }
    end
  end

  # Files a tree holds for one language, on either side of the boundary.
  def tree_paths(root, layout, locale)
    layout == :directory ? Dir["#{root}/#{locale}/*.json"] : Dir["#{root}/#{locale}.json"]
  end

  def flatten(obj, prefix = '', acc = {})
    case obj
    when Hash then obj.each { |key, value| flatten(value, prefix.empty? ? key.to_s : "#{prefix}.#{key}", acc) }
    when Array then obj.each_with_index { |value, index| flatten(value, "#{prefix}[#{index}]", acc) }
    else acc[prefix] = obj
    end
    acc
  end

  def keys_in(paths)
    paths.sort.each_with_object({}) do |path, acc|
      if path.end_with?('.json')
        acc.merge!(flatten(JSON.parse(File.read(path))))
      else
        # YAML locale files nest everything under the locale itself; drop that
        # root so keys are comparable across languages.
        tree = YAML.safe_load_file(path, aliases: true)
        acc.merge!(flatten(tree.values.first))
      end
    end
  end

  # Overrides are upstream keys we replace, so they are deliberately absent from
  # the fork's own key set and never count towards translation coverage.
  # Coverage is measured per bundle, not on the union: the dashboard and the survey load
  # different message trees at runtime, so one having a key translated says nothing about
  # the other, and merging them lets a translated dashboard key mask a missing survey one.
  def key_scopes(locale)
    scopes = FE_TREES.to_h { |tree| [tree[:fork], keys_in(tree_fork_paths(tree, locale))] }
    scopes.merge('config/locales' => keys_in(Dir["config/locales/fazer_ai*.#{locale}.yml"]))
  end

  def tree_fork_paths(tree, locale)
    tree_paths(tree[:fork], tree[:layout], locale).reject { |path| File.basename(path) == OVERRIDES }
  end

  # Only a directory-layout tree can carry overrides; a single-file tree has nowhere to
  # put them, and none of them needs to replace an upstream string today.
  def override_keys(tree, locale)
    return {} unless tree[:layout] == :directory

    path = File.join(tree[:fork], locale, OVERRIDES)
    File.exist?(path) ? keys_in([path]) : {}
  end

  def check_reference_locale_exists
    return if fork_locales.include?(REFERENCE_LOCALE)

    @errors << "#{FE_FORK}/#{REFERENCE_LOCALE} nao existe; ele e a referencia de chaves e o alvo do fallback"
  end

  # A fork key living in both trees means someone edited an upstream file.
  # JSON.parse keeps the last of two identical keys in one object and drops the first without a
  # word. A second `EVENTS` block appended to automation.json parsed, passed every check below and
  # hid the kanban automation events for two releases (chatwoot-pro#88). Scoped to the fork's own
  # files: upstream's are byte-identical to the release and not ours to fix.
  def check_fork_files_have_no_duplicated_keys
    ensure_parser_rejects_duplicated_keys
    FE_TREES.product(fork_locales).each do |tree, locale|
      tree_paths(tree[:fork], tree[:layout], locale).sort.each do |path|
        JSON.parse(File.read(path), allow_duplicate_key: false)
      rescue JSON::ParserError => e
        @errors << "#{path}: #{e.message}; o JSON fica so com a ultima ocorrencia"
      end
    end
  end

  # `allow_duplicate_key` arrived in json 2.13. An older parser ignores the option and keeps the
  # last value, which is the exact silence this check exists to break, so it fails on its own
  # instead of passing every file. Ruby 3.4 ships 2.9; the CI workflow installs a newer gem.
  def ensure_parser_rejects_duplicated_keys
    JSON.parse('{"a":1,"a":2}', allow_duplicate_key: false)
    abort "json #{JSON::VERSION} nao rejeita chaves duplicadas; instale json >= 2.13 (gem install json)"
  rescue JSON::ParserError
    nil
  end

  def check_fork_keys_are_not_duplicated_upstream
    FE_TREES.product(fork_locales).each { |tree, locale| check_tree_not_duplicated(tree, locale) }
  end

  def check_tree_not_duplicated(tree, locale)
    upstream = keys_in(tree_paths(tree[:upstream], tree[:layout], locale))
    duplicated = keys_in(tree_fork_paths(tree, locale)).keys & upstream.keys
    unless duplicated.empty?
      @errors << "#{tree[:fork]} #{locale}: #{duplicated.size} chaves do fork tambem existem no upstream (#{duplicated.first(3).join(', ')})"
    end

    # The mirror case: an override that upstream does not define replaces nothing, so it
    # belongs in a regular fork file instead.
    dangling = override_keys(tree, locale).keys - upstream.keys
    return if dangling.empty?

    @errors << "#{tree[:fork]} #{locale}: #{dangling.size} overrides nao existem no upstream (#{dangling.first(3).join(', ')})"
  end

  # Anything translated in another language but absent from the reference is
  # unreachable: no component can render a key that `en` never defines.
  def check_every_key_exists_in_reference
    return unless fork_locales.include?(REFERENCE_LOCALE)

    (fork_locales - [REFERENCE_LOCALE]).each do |locale|
      key_scopes(locale).each do |scope, keys|
        orphans = keys.keys - key_scopes(REFERENCE_LOCALE).fetch(scope, {}).keys
        next if orphans.empty?

        @errors << "#{scope} #{locale}: #{orphans.size} chaves nao existem em #{REFERENCE_LOCALE} (#{orphans.first(3).join(', ')})"
      end
    end
  end

  # The mirror case: a key the reference defines and another language does not
  # renders in English for that language. Upstream's other ~55 locales live off
  # that fallback, but the languages we ship are supposed to be complete, so a
  # gap here is an untranslated string, not a graceful degradation.
  # Overrides stay out of this on purpose: replacing an upstream string in one
  # language says nothing about whether upstream got the others right.
  def check_reference_keys_are_translated_everywhere
    return unless fork_locales.include?(REFERENCE_LOCALE)

    reference = key_scopes(REFERENCE_LOCALE)
    (fork_locales - [REFERENCE_LOCALE]).each do |locale|
      scopes = key_scopes(locale)
      reference.each do |scope, keys|
        missing = keys.keys - scopes.fetch(scope, {}).keys
        next if missing.empty?

        @errors << "#{scope} #{locale}: #{missing.size} chaves de #{REFERENCE_LOCALE} sem traducao (#{missing.first(3).join(', ')})"
      end
    end
  end

  def check_upstream_indexes_ignore_the_fork
    FE_TREES.flat_map { |tree| Dir["#{tree[:upstream]}/*/index.js"] }.each do |path|
      next unless File.read(path).include?('fazer-ai')

      @errors << "#{path} referencia a arvore do fork; o merge acontece em i18n/index.js"
    end
  end

  def report_coverage
    return unless fork_locales.include?(REFERENCE_LOCALE)

    reference = key_scopes(REFERENCE_LOCALE)
    total = reference.values.sum(&:size)
    puts "chaves do fork em #{REFERENCE_LOCALE}: #{total}"
    (fork_locales - [REFERENCE_LOCALE]).each do |locale|
      scopes = key_scopes(locale)
      translated = reference.sum { |scope, keys| (keys.keys & scopes.fetch(scope, {}).keys).size }
      puts format('  %<locale>-8s %<done>4d/%<total>d traduzidas (%<percent>d%%)',
                  locale: locale, done: translated, total: total, percent: (translated * 100.0 / total).round)
    end
  end

  def finish
    if @errors.empty?
      puts 'ok'
      exit 0
    end
    @errors.each { |error| puts "erro: #{error}" }
    exit 1
  end
end

command = ARGV[0] || 'check'
case command
when 'check' then ForkTranslations.new.check
when 'drift'
  base_index = ARGV.index('--base')
  ForkTranslations.new.drift(base_index ? ARGV[base_index + 1] : UPSTREAM_BASE)
when 'scaffold' then ForkTranslations.new.scaffold(ARGV[1])
else abort "comando desconhecido: #{command} (use check, drift ou scaffold)"
end
