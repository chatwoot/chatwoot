unless [].respond_to?(:freq)
  class Array
    def freq
      k=Hash.new(0)
      each { |e| k[e]+=1 }
      k
    end
  end
end