module ContactHelper
  def split_first_and_last_name(full_name)
    return { first_name: nil, last_name: nil } if full_name.nil?

    squished_full_name = full_name.squish

    # Handle names with phone numbers
    return { first_name: squished_full_name, last_name: nil } if squished_full_name.gsub(/\s+/, '').match?(/\A\+?\d+\z/)

    names = squished_full_name.split

    first_name = names.first || ''

    last_name = names.drop(1).join(' ')

    { first_name: first_name, last_name: last_name }
  end
end
