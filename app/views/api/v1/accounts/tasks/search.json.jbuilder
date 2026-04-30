json.payload do
  json.array! @tasks do |task|
    json.partial! 'task', task: task
  end
end

json.meta do
  json.count @tasks_count
  json.current_page @tasks.current_page
  json.total_pages @tasks.total_pages
end
