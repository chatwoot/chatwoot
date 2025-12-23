namespace :scout do
  desc "Prints out details of the detected environment"
  task :doctor => :environment do
    ScoutApm::Tasks::Doctor.run!
  end

  desc "Collect logs, settings and environment to help debug issues"
  task :support => :environment do
    ScoutApm::Tasks::Support.run!
  end
end
