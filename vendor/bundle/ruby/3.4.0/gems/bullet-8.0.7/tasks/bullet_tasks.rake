# frozen_string_literal: true

namespace :bullet do
  namespace :log do
    desc 'Truncates the bullet log file to zero bytes'
    task :clear do
      f = File.open('log/bullet.log', 'w')
      f.close
    end
  end
end
