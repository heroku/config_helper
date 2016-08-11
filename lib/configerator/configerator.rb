require 'uri'

module Configerator
  def required(name, method=nil, error_on_load: true)
    # Hash#fetch raises a KeyError, Hash#[] doesn't
    value = error_on_load ? ENV.fetch(name.to_s.upcase) : ENV[name.to_s.upcase]
    value = cast(value, method)

    create(name, value, error_on_load)
  end

  def optional(name, method=nil)
    value = cast(ENV[name.to_s.upcase], method)
    create(name, value)
  end

  def override(name, default, method=nil)
    value = cast(ENV.fetch(name.to_s.upcase, default), method)
    create(name, value)
  end

  def int
    ->(v) { v.to_i }
  end

  def float
    ->(v) { v.to_f }
  end

  def bool
    ->(v) { v.to_s=='true'}
  end

  def string
    nil
  end

  def symbol
    ->(v) { v.to_sym }
  end

  def url
    ->(v) { v && URI.parse(v) }
  end

  # optional :accronyms, array(string)
  # => ['a', 'b']
  # optional :numbers, array(int)
  # => [1, 2]
  # optional :notype, array
  # => ['a', 'b']
  def array(method = nil)
    -> (v) do
      if v
        v.split(',').map{|a| cast(a, method) }
      end
    end
  end

  private

  def cast(value, method)
    method ? method.call(value) : value
  end

  def create(name, value, error_on_load=true)
    instance_variable_set(:"@#{name}", value)
    instance_eval "def #{name}; @#{name} || (raise \"key not set '#{name}'\" unless #{error_on_load}) end"
    instance_eval "def #{name}?; !!@#{name} end", __FILE__, __LINE__
  end
end
