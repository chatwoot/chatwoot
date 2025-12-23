module Brakeman
  module SafeCallHelper
    [[:process_safe_call, :process_call],
     [:process_safe_attrasgn, :process_attrasgn],
     [:process_safe_op_asgn, :process_op_asgn],
     [:process_safe_op_asgn2, :process_op_asgn2]].each do |call, replacement|
       define_method(call) do |exp|
         if self.respond_to? replacement
           self.send(replacement, exp)
         else
           process_default exp
         end
       end
     end
  end
end
