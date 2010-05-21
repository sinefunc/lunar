module Lunar
  # This wraps a Lunar search result set. You can do all the
  # expected operations with an Enumerable.
  #
  #   results = Lunar.search(Gadget, :q => "Apple Macbook Pro")
  #   results.class == Lunar::ResultSet
  #   # => true
  #
  #   results.kind_of?(Enumerable)
  #   # => true
  #
  # {Lunar::ResultSet#sort} and {Lunar::ResultSet#sort_by} commands are 
  # available and directly calls the Redis SORT command.
  #
  #   results = Lunar.search(Gadget, :q => "Apple Macbook Pro")
  #   results.sort(:by => :name, :order => "ALPHA")
  #   results.sort(:by => :name, :order => "ALPHA ASC")
  #   results.sort(:by => :name, :order => "ALPHA DESC")
  #
  # @see http://code.google.com/p/redis/wiki/SortCommand
  class ResultSet
    include Enumerable

    attr :distkey
    attr :nest
    attr :sortables

    def initialize(distkey, nest, finder)
      @distkey   = distkey
      @nest      = nest
      @finder    = finder
      @sortables = @nest[:Sortables]['*']
    end

    def each
      objects(distkey.zrange(0, -1)).each { |e| yield e }
    end

    # Provides syntatic sugar for `sort`.
    #
    # @example
    #
    #   results = Lunar.search(Gadget, :q => "apple")
    #   results.sort(:by => :votes)
    #   results.sort_by(:votes)
    #
    # @param [#to_s] att the field in the namespace you want to sort by.
    # @param [Hash] opts the various opts to pass to Redis SORT command.
    # @option opts [#to_s] :order the direction you want to sort i.e. ASC DESC ALPHA
    # @option opts [Array] :limit offset and max results to return.
    #
    # @return [Array] Array of objects as defined by the `finder`.
    # @see http://code.google.com/p/redis/wiki/SortCommand
    def sort_by(att, opts = {})
      sort(opts.merge(:by => att))
    end

    # Gives the ability to sort the search results via a `sortable` field
    # in your index.
    #
    # @example
    #
    #   Lunar.index Gadget do |i|
    #     i.id 1001
    #     i.text :title, "Apple Macbook Pro"
    #     i.sortable :votes, 10
    #   end
    #
    #   Lunar.index Gadget do |i|
    #     i.id 1002
    #     i.text :title, "Apple iPad"
    #     i.sortable :votes, 50
    #   end
    #
    #   results = Lunar.search(Gadget, :q => "apple")
    #   sorted  = results.sort(:by => :votes, :order => "DESC")
    #
    #   sorted == [Gadget[1002], Gadget[1001]]
    #   # => true
    #
    # @param [Hash] opts the various opts to pass to Redis SORT command.
    # @option opts [#to_s] :by the field in the namespace you want to sort by.
    # @option opts [#to_s] :order the direction you want to sort i.e. ASC DESC ALPHA
    # @option opts [Array] :limit offset and max results to return.
    #
    # @return [Array] Array of objects as defined by the `finder`.
    # @see http://code.google.com/p/redis/wiki/SortCommand
    def sort(opts = {})
      opts[:by] = sortables[opts[:by]]  if opts[:by]
      objects(distkey.sort(opts))
    end

  protected
    def objects(ids)
      ids.map(&@finder)
    end
  end
end
