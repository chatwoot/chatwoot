require 'rails_helper'

RSpec.describe DataImports::BaseJob do
  %w[freshdesk intercom].each do |provider|
    context "with a #{provider} import" do
      let(:account) { create(:account) }
      let(:data_import) { create(:data_import, provider.to_sym, account: account, status: :processing) }
      let(:run_id) { 'connection-retry-run' }
      let(:importer_class) { "DataImports::#{provider.camelize}::Importer".constantize }
      let(:page_job_class) { "DataImports::#{provider.camelize}::ConversationsPageJob".constantize }
      let(:importer) { importer_class.new(data_import: data_import, run_id: run_id) }
      let(:connection) { ApplicationRecord.connection }

      before do
        account.enable_features!('data_import')
        data_import.update!(source_metadata: data_import.source_metadata.merge(DataImport::ACTIVE_IMPORT_RUN_ID_KEY => run_id))
        # Instantiate before stubbing the constructor used by the real page job.
        importer
        allow(importer_class).to receive(:new).with(data_import: data_import, run_id: run_id).and_return(importer)
        allow(importer).to receive(:conversations_completed?).and_return(false)
        allow(importer).to receive(:fail!).and_call_original
        allow(connection).to receive(:disconnect!)
        clear_enqueued_jobs
      end

      [ActiveRecord::ConnectionNotEstablished, ActiveRecord::ConnectionFailed].each do |error_class|
        it "retries #{error_class.name} without making the import terminal", :aggregate_failures do
          allow(importer).to receive(:import_conversations_page).and_raise(error_class, 'database disconnected')

          freeze_time do
            expect { page_job_class.perform_now(data_import, nil, run_id) }
              .to have_enqueued_job(page_job_class).with(data_import, nil, run_id).on_queue('low')
            expect(enqueued_jobs.last[:at]).to be_between(3.seconds.from_now.to_f, 4.seconds.from_now.to_f)
          end

          expect(connection).to have_received(:disconnect!).once
          expect(importer).not_to have_received(:fail!)
          expect(data_import.reload).to be_processing
          expect(data_import.import_errors).to be_empty
        end
      end

      it 'records a run failure after the third connection attempt', :aggregate_failures do
        error = ActiveRecord::ConnectionNotEstablished.new('database disconnected')
        allow(importer).to receive(:import_conversations_page).and_raise(error)
        job = page_job_class.new(data_import, nil, run_id)
        job.exception_executions[DataImports::Importer::CONNECTION_ERRORS.to_s] = 2

        expect { job.perform_now }.not_to have_enqueued_job(page_job_class)

        expect(importer).to have_received(:fail!).with(error).once
        expect(data_import.reload).to be_failed
        expect(data_import.last_error_at).to be_present
        expect(data_import.import_errors.sole.error_code).to eq('ActiveRecord::ConnectionNotEstablished')
      end

      it 'retries a database outage during GlobalID lookup with the original arguments', :aggregate_failures do
        error = ActiveRecord::ConnectionNotEstablished.new('lookup disconnected')
        lookups = 0
        allow(GlobalID::Locator).to receive(:locate).and_wrap_original do |method, *args|
          lookups += 1
          raise error if lookups == 1

          method.call(*args)
        end
        serialized = page_job_class.new(data_import, nil, run_id).serialize

        expect { ActiveJob::Base.execute(serialized) }.to have_enqueued_job(page_job_class).with(data_import, nil, run_id)

        expect(connection).to have_received(:disconnect!).once
        expect(importer).not_to have_received(:fail!)
        expect(data_import.reload).to be_processing
      end

      it 'leaves an unresolved GlobalID job available for backend retries after exhaustion', :aggregate_failures do
        allow(GlobalID::Locator).to receive(:locate).and_raise(ActiveRecord::ConnectionNotEstablished, 'lookup disconnected')
        serialized = page_job_class.new(data_import, nil, run_id).serialize
        serialized['exception_executions'][DataImports::Importer::CONNECTION_ERRORS.to_s] = 2

        expect { ActiveJob::Base.execute(serialized) }.to raise_error do |error|
          expect(error.class.name).to eq('ActiveRecord::ConnectionNotEstablished')
        end

        expect(enqueued_jobs).to be_empty
        expect(importer).not_to have_received(:fail!)
        expect(data_import.reload).to be_processing
      end

      it 'keeps the existing discard behavior for a deleted import' do
        allow(GlobalID::Locator).to receive(:locate).and_raise(ActiveRecord::RecordNotFound, 'deleted import')
        serialized = page_job_class.new(data_import, nil, run_id).serialize

        expect { ActiveJob::Base.execute(serialized) }.not_to have_enqueued_job(page_job_class)
      end

      it 'does not retry unrelated database errors', :aggregate_failures do
        allow(importer).to receive(:import_conversations_page).and_raise(ActiveRecord::StatementInvalid, 'invalid SQL')

        expect { page_job_class.perform_now(data_import, nil, run_id) }.to raise_error do |error|
          expect(error.class.name).to eq('ActiveRecord::StatementInvalid')
        end

        expect(enqueued_jobs).to be_empty
        expect(connection).not_to have_received(:disconnect!)
        expect(data_import.reload).to be_failed
      end
    end
  end
end
