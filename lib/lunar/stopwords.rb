module Lunar
  # @private Internally used by {Lunar::Words} to filter out
  # common words like an, the, etc.
  module Stopwords
    def include?(word)
      stopwords.include?(word)
    end

  private
    def stopwords
      %w(an and are as at be but by for if in into is it no not of on or s 
         such t that the their then there these they this to was will with)
    end

    module_function :stopwords, :include?
  end
end
