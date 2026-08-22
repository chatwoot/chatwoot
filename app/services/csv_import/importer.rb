# frozen_string_literal: true

# Imports contacts (and their companies) from an arbitrary CSV export.
#
# Dedup rules (per account, applied in order):
#   1. Contact with the same normalized email        -> update existing
#   2. Contact with the same E.164 phone number       -> update existing
#   3. Contact with the same name AND city            -> update existing
#   4. Otherwise                                      -> create new
#
# Companies are deduped by (name) within the account (case-insensitive). A
# contact is always linked to its company via contacts.company_id.
#
# Designed to be removable: nothing in the core app calls this except
# CsvImportController. Delete the app/services/csv_import dir + controller to
# remove the feature.
module CsvImport
  class Importer
    pattr_initialize [:account!, :csv_io!, :options]

    RESULT_KEYS = %i[created updated skipped companies_created companies_updated rows contact_ids].freeze

    def perform
      rows = parse_csv
      results = initial_results

      rows.each do |row|
        parsed = CsvImport::Row.new(row, @header_lookup)
        next results[:skipped] += 1 if parsed.blank?

        company = upsert_company(parsed, results)
        contact = upsert_contact(parsed, company, results)
        results[:contact_ids] << contact.id if contact
        results[:rows] += 1
      end

      results
    end

    private

    def parse_csv
      content = csv_io.respond_to?(:read) ? csv_io.read : csv_io.to_s
      # Normalise line endings for Windows exports.
      content = content.gsub("\r\n", "\n").gsub("\r", "\n")
      @table = CSV.parse(content, headers: true)
      @header_lookup = CsvImport::ColumnMap.lookup(@table.headers)
      @table.map(&:to_h)
    rescue CSV::MalformedCSVError => e
      Rails.logger.error("CsvImport: malformed CSV - #{e.message}")
      []
    end

    def initial_results
      { created: 0, updated: 0, skipped: 0, companies_created: 0, companies_updated: 0, rows: 0, contact_ids: [] }
    end

    # --- Company ---------------------------------------------------------

    def upsert_company(parsed, results)
      company_name = parsed.company_name
      return nil if company_name.blank?

      domain = parsed.company_domain
      company = account.companies.where('lower(name) = ?', company_name.downcase).first

      if company
        # Merge newly-seen attributes without clobbering existing ones.
        merged = company.custom_attributes.merge(parsed.social_attributes)
        company.update(custom_attributes: merged, domain: domain.presence || company.domain)
        results[:companies_updated] += 1 if company.previous_changes.present?
        return company
      end

      company = account.companies.create!(
        name: company_name,
        domain: domain,
        custom_attributes: parsed.social_attributes
      )
      results[:companies_created] += 1
      company
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("CsvImport: company create failed - #{e.message}")
      nil
    end

    # --- Contact ---------------------------------------------------------

    def upsert_contact(parsed, company, results)
      contact = find_existing_contact(parsed)
      attrs = build_contact_attributes(parsed, company)

      if contact
        contact.assign_attributes(attrs)
        if contact.changed?
          contact.save!
          results[:updated] += 1
        end
        return contact
      end

      contact = account.contacts.create!(attrs)
      results[:created] += 1
      contact
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("CsvImport: contact create failed - #{e.message}")
      results[:skipped] += 1
      nil
    end

    def find_existing_contact(parsed)
      scope = account.contacts
      return scope.find_by(email: parsed.email) if parsed.email.present?
      return scope.find_by(phone_number: parsed.phone_number) if parsed.phone_number.present?

      if parsed.name.present?
        by_name = scope.where(name: parsed.name)
        return by_name.find_by(city: parsed.city) if parsed.city.present?

        return by_name.first if by_name.count == 1
      end
      nil
    end

    def build_contact_attributes(parsed, company)
      attrs = {
        name: parsed.name,
        email: parsed.email,
        phone_number: parsed.phone_number,
        city: parsed.city,
        country: parsed.country,
        location: parsed.address,
        company_id: company&.id,
        custom_attributes: parsed.extra_custom_attributes.merge(parsed.social_attributes)
      }
      attrs.compact
    end
  end
end
