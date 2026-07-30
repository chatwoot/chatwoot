class DataImports::Freshdesk::Importer < DataImports::Importer
  InvalidMessagePayloadError = DataImports::Importer::InvalidMessagePayloadError
  ALREADY_IMPORTED_ERROR_CODE = DataImports::Freshdesk::Source::ALREADY_IMPORTED_ERROR_CODE
  SKIPPED_MESSAGE_ERROR_CODE = DataImports::Freshdesk::Source::SKIPPED_MESSAGE_ERROR_CODE
  TRUNCATED_PARTS_ERROR_CODE = DataImports::Freshdesk::Source::TRUNCATED_PARTS_ERROR_CODE
end
