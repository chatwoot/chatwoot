## we had instances where after copy pasting the schedule block,
## the dev forgets to changes the schedule key,
## this would break some of the scheduled jobs with out explicit errors
require 'rails_helper'

RSpec.context 'with valid schedule.yml' do
  it 'does not have duplicates' do
    file = Rails.root.join('config/schedule.yml')
    schedule_keys = []
    invalid_line_starts = [' ', '#', "\n"]
    # couldn't figure out a proper solution with yaml.parse
    # so the rudementary solution is to read the file and parse it
    # check for duplicates in the array
    File.open(file).each do |f|
      f.each_line do |line|
        next if invalid_line_starts.include?(line[0])

        schedule_keys << line.split(':')[0]
      end
    end
    # ensure that no duplicates exist
    expect(schedule_keys.count).to eq(schedule_keys.uniq.count)
  end

  describe 'auto resolve schedule' do
    def resolution_cron
      schedule = Sidekiq::Cron::Support.load_yaml(ERB.new(Rails.root.join('config/schedule.yml').read).result)
      schedule['trigger_conversations_resolution_job']['cron']
    end

    it 'runs every 5 minutes by default' do
      expect(resolution_cron).to eq('*/5 * * * *')
    end

    it 'uses AUTO_RESOLVE_CRON when set' do
      with_modified_env AUTO_RESOLVE_CRON: '* * * * *' do
        expect(resolution_cron).to eq('* * * * *')
      end
    end
  end
end
