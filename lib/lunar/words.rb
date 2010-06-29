require 'iconv'

module Lunar
  # @private Internally used to determine the words given some str.
  # i.e. Words.new("the quick brown") == %w(the quick brown)
  class Words < Array
    UnknownFilter = Class.new(ArgumentError)

    SEPARATOR = /\s+/
    FILTERS   = [:stopwords, :downcase]

    def initialize(str, filters = [])
      words = str.split(SEPARATOR).
        reject { |w| w.to_s.strip.empty? }.
        map    { |w| sanitize(w) }
    
      apply_filters(words, filters)

      super(words)
    end

  private
    def apply_filters(words, filters)
      filters.each do |filter|
        unless FILTERS.include?(filter)
          raise UnknownFilter, "Unknown filter: #{ filter }"
        end
        
        send(filter, words)
      end
    end

    def stopwords(words)
      words.reject! { |w| Stopwords.include?(w) }
    end

    def downcase(words)
      words.each { |w| w.downcase! }
    end

    def sanitize(str)
      Iconv.iconv('UTF-8//IGNORE//TRANSLIT', 'UTF-8', str)[0].to_s.
        gsub(/["'\.,@!$%\^&\*\(\)\[\]\+\-\_\:\;\<\>\\\/\?\`\~]/, '')
    end
  end
end
