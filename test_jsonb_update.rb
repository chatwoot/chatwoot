message = Message.last
message.content_attributes['test'] = []
message.save!

# Test 1: Mutate in place, then call will_change!
test_arr = message.content_attributes['test']
test_arr << 'hello'
message.content_attributes_will_change!
message.content_attributes['test'] = test_arr
puts "Test 1 saved? #{message.save}"
puts "Test 1 previous_changes: #{message.previous_changes}"

# Test 2: Call will_change! BEFORE mutating
message.content_attributes_will_change!
test_arr = message.content_attributes['test']
test_arr << 'world'
message.content_attributes['test'] = test_arr
puts "Test 2 saved? #{message.save}"
puts "Test 2 previous_changes: #{message.previous_changes}"

# Test 3: Reassign a completely new object
test_arr = message.content_attributes['test'].dup
test_arr << 'again'
message.content_attributes = message.content_attributes.merge('test' => test_arr)
puts "Test 3 saved? #{message.save}"
puts "Test 3 previous_changes: #{message.previous_changes}"
