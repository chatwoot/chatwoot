json.array! @assignment_policies do |assignment_policy|
  json.partial! 'assignment_policy', assignment_policy: assignment_policy
end
