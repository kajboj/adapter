class AdapterFactory
  attr_reader :map

  def self.static(response)
    lambda do |object, method, args, blk|
      response
    end
  end

  ALWAYS_NIL = self.static(nil)

  IDENTITY = lambda do |object, method, args, blk|
    object.send(method, *args, &blk)
  end

  def initialize(map = {}, &blk)
    @map = map
    @blk = blk
  end

  def wrap(object)
    adapter = Adapter.new(object, @map)
    adapter.instance_eval &@blk if @blk
    adapter
  end

  class Adapter
    attr_reader :adaptee

    def initialize(adaptee, map)
      @adaptee = adaptee
      @map = map
    end

    def method_missing(m, *args, &blk)
      symbol_or_lambda =  @map[m.to_sym] || IDENTITY
      if symbol_or_lambda.is_a? Symbol
        adaptee.send(symbol_or_lambda, *args, &blk)
      else
        symbol_or_lambda.call(adaptee, m, args, blk)
      end
    end
    
    def to_hash
      {}.tap do |h|
        only_no_argument_methods.each_pair do |adapter_method, adaptee_method|
          h[adapter_method] = adaptee.send(adaptee_method)
        end
      end
    end

    private
      
    def only_no_argument_methods
      {}.tap do |h|
        @map.each_pair do |adapter_method, adaptee_method|
          if !adaptee_method.is_a?(Proc) && [0, -1].include?(adaptee.method(adaptee_method).arity)
            h[adapter_method] = adaptee_method 
          end
        end
      end
    end
  end
end
