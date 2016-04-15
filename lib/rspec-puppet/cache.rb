module RSpec::Puppet
  class Cache

    MAX_ENTRIES = 16

    # @param [Proc] default_proc The default proc to use to fetch objects on cache miss
    def initialize(&default_proc)
      @default_proc = default_proc
      @cache = {}
      @lra = []
      @missed = 0
      @hit = 0
    end

    def get(*args, &blk)
      # decouple the hash key from whatever the blk might do to it
      key = Marshal.load(Marshal.dump(args))
      if !@cache.has_key? key
        puts "CACHE MISS!"
        @missed = @missed + 1
        @cache[key] = (blk || @default_proc).call(*args)
        @lra << key
        expire!
      else
        puts "CACHE HIT!"
        @hit = @hit + 1
      end
      puts "HIT RATE: #{100*@hit/(@hit+@missed)}%"
      @cache[key]
    end

    private

    def expire!
      puts "lra.size = #{@lra.size}"
      expired = @lra.slice!(0, @lra.size - MAX_ENTRIES)
      puts "Expiring #{expired.size} cache entries" if expired
      expired.each { |key| @cache.delete(key) } if expired
    end
  end
end
