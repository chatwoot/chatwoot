require 'rake'
require 'rails_helper'

RSpec.describe Rake::Task do
  describe 'storage_migrations' do
    describe 'rake task' do
      context 'when FROM argument is missing' do
        before do
          ENV['FROM'] = nil
        end

        it 'raises an error' do
          expect do
            described_class['storage:migrate'].invoke
          end.to raise_error(RuntimeError,
                             'Missing FROM or TO argument. Usage: FROM=service_name TO=service_name rake storage:migrate')
        end
      end

      context 'when TO argument is missing' do
        before do
          ENV['FROM'] = 'service_name'
          ENV['TO'] = nil
        end

        it 'raises an error' do
          expect do
            described_class['storage:migrate'].invoke
          end.to raise_error(RuntimeError,
                             'Missing FROM or TO argument. Usage: FROM=service_name TO=service_name rake storage:migrate')
        end
      end
    end
  end
end
