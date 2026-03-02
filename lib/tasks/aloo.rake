# frozen_string_literal: true

namespace :aloo do
  desc 'Re-embed all documents with the current embedding model (after model change or migration)'
  task reembed_all: :environment do
    documents = Aloo::Document.where(status: :available)
    total = documents.count

    if total.zero?
      puts 'No available documents to re-embed.'
      next
    end

    puts "Queuing #{total} documents for re-embedding..."

    documents.find_each.with_index(1) do |document, index|
      Aloo::ProcessDocumentJob.perform_later(document.id)
      puts "  [#{index}/#{total}] Queued: #{document.title}"
    end

    puts "Done! #{total} documents queued for re-embedding via ProcessDocumentJob."
  end
end
