require 'iconv'

module Lunar
  # @private Internally used to determine the words given some str.
  # i.e. Words.new("the quick brown") == %w(the quick brown)
  class Words < Array
    SEPARATOR = /\s+/

    def initialize(str)
      words = str.split(SEPARATOR).
        reject { |w| w.to_s.strip.empty? }.
        map    { |w| sanitize(w) }.
        reject { |w| Stopwords.include?(w) }

      super(words)
    end

  private
    def sanitize(str)
      Iconv.iconv('UTF-8//IGNORE', 'UTF-8', str)[0].to_s.
        gsub(/[^a-zA-Z0-9\-_]/, '').downcase
    end
  end
end