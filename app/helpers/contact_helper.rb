module ContactHelper
  def split_first_and_last_name(full_name)
    return { first_name: nil, last_name: nil } if full_name.nil?

    # Remove extra spaces and split the name
    names = full_name.squish.split

    first_name = names.first || ''

    last_name = names.drop(1).join(' ')

    { first_name: first_name, last_name: last_name }
  end
end
