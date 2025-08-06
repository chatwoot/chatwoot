require 'rails_helper'

RSpec.describe Captain::ResponseBuilderJob, type: :job do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:document) { create(:captain_document, assistant: assistant, account: account) }
  let(:user) { create(:user, account: account) }

  describe '#perform' do
    let(:job_params) do
      {
        account_id: account.id,
        assistant_id: assistant.id,
        document_id: document.id,
        user_id: user.id,
        requested_faq_count: 10
      }
    end

    context 'when generating FAQs with pagination' do
      it 'calls paginated FAQ generator service' do
        paginated_service = instance_double(Captain::Llm::PaginatedFaqGeneratorService)
        expect(Captain::Llm::PaginatedFaqGeneratorService).to receive(:new).with(
          document: document,
          assistant: assistant,
          requested_faq_count: 10
        ).and_return(paginated_service)
        expect(paginated_service).to receive(:perform)

        described_class.perform_now(job_params)
      end

      it 'handles different FAQ count requests' do
        [5, 10, 15, 20].each do |count|
          params = job_params.merge(requested_faq_count: count)
          paginated_service = instance_double(Captain::Llm::PaginatedFaqGeneratorService)

          expect(Captain::Llm::PaginatedFaqGeneratorService).to receive(:new).with(
            document: document,
            assistant: assistant,
            requested_faq_count: count
          ).and_return(paginated_service)
          expect(paginated_service).to receive(:perform)

          described_class.perform_now(params)
        end
      end

      it 'stores metadata about FAQ generation' do
        paginated_service = instance_double(Captain::Llm::PaginatedFaqGeneratorService)
        allow(Captain::Llm::PaginatedFaqGeneratorService).to receive(:new).and_return(paginated_service)
        allow(paginated_service).to receive(:perform).and_return({
                                                                   faqs_generated: 10,
                                                                   pages_processed: 2,
                                                                   generation_time: 5.2
                                                                 })

        described_class.perform_now(job_params)

        expect(document.reload.metadata['faq_generation']).to include(
          'faqs_generated' => 10,
          'pages_processed' => 2,
          'generation_time' => 5.2
        )
      end
    end

    context 'when FAQ count is not specified' do
      let(:job_params_without_count) do
        {
          account_id: account.id,
          assistant_id: assistant.id,
          document_id: document.id,
          user_id: user.id
        }
      end

      it 'uses default FAQ count' do
        paginated_service = instance_double(Captain::Llm::PaginatedFaqGeneratorService)
        expect(Captain::Llm::PaginatedFaqGeneratorService).to receive(:new).with(
          document: document,
          assistant: assistant,
          requested_faq_count: 10 # default value
        ).and_return(paginated_service)
        expect(paginated_service).to receive(:perform)

        described_class.perform_now(job_params_without_count)
      end
    end

    context 'when generation strategy is specified' do
      let(:job_params_with_strategy) do
        job_params.merge(generation_strategy: 'chunked')
      end

      it 'passes strategy to the service' do
        paginated_service = instance_double(Captain::Llm::PaginatedFaqGeneratorService)
        expect(Captain::Llm::PaginatedFaqGeneratorService).to receive(:new).with(
          document: document,
          assistant: assistant,
          requested_faq_count: 10,
          strategy: 'chunked'
        ).and_return(paginated_service)
        expect(paginated_service).to receive(:perform)

        described_class.perform_now(job_params_with_strategy)
      end
    end

    context 'when pagination is required for large documents' do
      it 'processes document in chunks' do
        paginated_service = instance_double(Captain::Llm::PaginatedFaqGeneratorService)
        allow(Captain::Llm::PaginatedFaqGeneratorService).to receive(:new).and_return(paginated_service)

        expect(paginated_service).to receive(:perform) do
          # Simulate paginated processing
          3.times do |page|
            # Process each page
          end
          { faqs_generated: 30, pages_processed: 3 }
        end

        described_class.perform_now(job_params.merge(requested_faq_count: 30))
      end
    end

    context 'when service raises an error' do
      it 'propagates the error' do
        paginated_service = instance_double(Captain::Llm::PaginatedFaqGeneratorService)
        allow(Captain::Llm::PaginatedFaqGeneratorService).to receive(:new).and_return(paginated_service)
        allow(paginated_service).to receive(:perform).and_raise(StandardError, 'Generation failed')

        expect { described_class.perform_now(job_params) }
          .to raise_error(StandardError, 'Generation failed')
      end

      it 'logs the error details' do
        paginated_service = instance_double(Captain::Llm::PaginatedFaqGeneratorService)
        allow(Captain::Llm::PaginatedFaqGeneratorService).to receive(:new).and_return(paginated_service)
        allow(paginated_service).to receive(:perform).and_raise(StandardError, 'Generation failed')

        expect(Rails.logger).to receive(:error).with(/FAQ generation failed/)

        expect { described_class.perform_now(job_params) }
          .to raise_error(StandardError)
      end
    end

    context 'when document is not found' do
      it 'raises ActiveRecord::RecordNotFound' do
        invalid_params = job_params.merge(document_id: -1)

        expect { described_class.perform_now(invalid_params) }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when assistant is not found' do
      it 'raises ActiveRecord::RecordNotFound' do
        invalid_params = job_params.merge(assistant_id: -1)

        expect { described_class.perform_now(invalid_params) }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'job queuing' do
    it 'is enqueued in the default queue' do
      expect do
        described_class.perform_later(
          account_id: account.id,
          assistant_id: assistant.id,
          document_id: document.id,
          user_id: user.id
        )
      end.to have_enqueued_job(described_class).on_queue('default')
    end

    it 'can be scheduled for later execution' do
      expect do
        described_class.set(wait: 5.minutes).perform_later(
          account_id: account.id,
          assistant_id: assistant.id,
          document_id: document.id,
          user_id: user.id
        )
      end.to have_enqueued_job(described_class).at(5.minutes.from_now)
    end
  end
end
