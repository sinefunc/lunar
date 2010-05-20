module Lunar
  class FuzzyWord < String
    def partials
      (1..length).map { |i| self[0, i].downcase }
    end
  end
end