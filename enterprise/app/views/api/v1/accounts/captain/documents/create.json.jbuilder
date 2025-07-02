json.document do
  json.partial! 'api/v1/models/captain/document', formats: [:json], resource: @document
end

# Include message for PDF uploads
json.message 'PDF uploaded successfully. Processing will begin shortly.' if @document.source_type == 'pdf_upload'
