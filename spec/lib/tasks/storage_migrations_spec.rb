require 'rails_helper'
require 'rake'

RSpec.describe 'storage_migrations' do
  describe 'rake task' do

    context 'when FROM argument is missing' do
      before do
        ENV['FROM'] = nil
      end

      it 'raises an error' do
        expect { Rake::Task['storage:migrate'].invoke }.to raise_error(RuntimeError, 'Missing FROM or TO argument. Usage: FROM=service_name TO=service_name rake storage:migrate')
      end
    end

    context 'when TO argument is missing' do
      before do
        ENV['FROM'] = 'service_name'
        ENV['TO'] = nil
      end

      it 'raises an error' do
        expect { Rake::Task['storage:migrate'].invoke }.to raise_error(RuntimeError, 'Missing FROM or TO argument. Usage: FROM=service_name TO=service_name rake storage:migrate')
      end
    end
  end
end
