require 'rake'
require 'rails_helper'

RSpec.describe Rake::Task do
  describe 'storage_migrations' do
    describe 'rake task' do
      subject(:task) { described_class['storage:migrate'] }

      before do
        task.reenable
      end

      context 'when FROM argument is missing' do
        it 'raises an error' do
          with_modified_env FROM: nil, TO: 'amazon' do
            expect do
              task.invoke
            end.to raise_error(RuntimeError,
                               'Missing FROM or TO argument. Usage: FROM=service_name TO=service_name rake storage:migrate')
          end
        end
      end

      context 'when TO argument is missing' do
        it 'raises an error' do
          with_modified_env FROM: 'service_name', TO: nil do
            expect do
              task.invoke
            end.to raise_error(RuntimeError,
                               'Missing FROM or TO argument. Usage: FROM=service_name TO=service_name rake storage:migrate')
          end
        end
      end

      context 'when required arguments are present' do
        it 'updates blob service names by default' do
          expect(ActiveStorage::Migrator).to receive(:migrate).with(:local, :amazon, should_update_service_name: true)

          with_modified_env FROM: 'local', TO: 'amazon', UPDATE_BLOB_SERVICE_NAME: nil do
            task.invoke
          end
        end

        it 'skips updating blob service names when disabled' do
          expect(ActiveStorage::Migrator).to receive(:migrate).with(:local, :amazon, should_update_service_name: false)

          with_modified_env FROM: 'local', TO: 'amazon', UPDATE_BLOB_SERVICE_NAME: 'false' do
            task.invoke
          end
        end

        it 'can be invoked again after the task is re-enabled' do
          expect(ActiveStorage::Migrator).to receive(:migrate).twice.with(:local, :amazon, should_update_service_name: true)

          with_modified_env FROM: 'local', TO: 'amazon', UPDATE_BLOB_SERVICE_NAME: nil do
            task.invoke
            task.reenable
            task.invoke
          end
        end
      end
    end
  end
end
