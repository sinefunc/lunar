module Lunar
  # @private internally used by Lunar::Index to count the words
  # of a given text.
  class Scoring
    def initialize(words)
      @words = Words.new(words, [:stopwords, :downcase])
    end

    def scores
      @words.inject(Hash.new(0)) { |a, w| a[w] += 1 and a }
    end
  end
end
