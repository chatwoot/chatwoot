json.payload do
  json.array! @tickets do |ticket|
    json.partial! 'api/v1/models/ticket', formats: [:json], resource: ticket
  end
end

json.meta do
  json.all @tickets.count
  json.pending @tickets.where(status: 'pending').count
  json.resolved @tickets.where(status: 'resolved').count
end
