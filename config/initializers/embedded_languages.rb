# These Ruby libraries load their own files and share interpreter class identity
# across requests. Do not let the app reloader unload only part of either library.
# https://guides.rubyonrails.org/v7.2/autoloading_and_reloading_constants.html#use-case-2-during-boot-load-code-that-remains-cached
Rails.autoloaders.main.ignore(
  Rails.root.join('lib/scheme.rb'), Rails.root.join('lib/scheme'),
  Rails.root.join('lib/wootql.rb'), Rails.root.join('lib/wootql')
)
require Rails.root.join('lib/scheme').to_s
require Rails.root.join('lib/wootql').to_s
