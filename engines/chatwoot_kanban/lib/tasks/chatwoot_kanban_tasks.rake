namespace :chatwoot_kanban do
  desc 'Install: copy migrations and link frontend files. Run once after `bundle install`.'
  task install: :environment do
    sh 'bundle exec rails chatwoot_kanban:install:migrations'
    Rake::Task['chatwoot_kanban:link_frontend'].invoke
    puts "\n[chatwoot_kanban] installed."
    puts 'Next steps:'
    puts '  1) bundle exec rails db:migrate'
    puts '  2) Add this line to config/routes.rb (at end, inside Rails.application.routes.draw):'
    puts '       mount ChatwootKanban::Engine => "/"'
    puts '  3) Register the Vuex module + routes in the dashboard (see engines/chatwoot_kanban/INSTALL.md).'
    puts '  4) Run pnpm install && pnpm build.'
  end

  desc 'Symlink (or copy) the Vue frontend into app/javascript/dashboard/modules/kanban.'
  task :link_frontend do
    require 'fileutils'
    engine_root  = File.expand_path('../../../', __dir__)
    src          = File.join(engine_root, 'frontend')
    target       = Rails.root.join('app/javascript/dashboard/modules/kanban')

    if File.exist?(target)
      puts "[chatwoot_kanban] #{target} already exists — skipping."
    else
      FileUtils.mkdir_p(File.dirname(target))
      begin
        File.symlink(src, target)
        puts "[chatwoot_kanban] symlinked frontend → #{target}"
      rescue Errno::EPERM, NotImplementedError
        FileUtils.cp_r(src, target)
        puts "[chatwoot_kanban] copied frontend → #{target} (symlinks unavailable)"
      end
    end
  end

  desc 'Uninstall the engine cleanly (drops tables — DESTRUCTIVE).'
  task uninstall: :environment do
    ActiveRecord::Base.connection.tap do |c|
      %w[chatwoot_kanban_card_activities chatwoot_kanban_cards
         chatwoot_kanban_columns chatwoot_kanban_boards].each do |t|
        c.drop_table(t) if c.table_exists?(t)
      end
    end
    puts '[chatwoot_kanban] tables dropped.'
  end
end
