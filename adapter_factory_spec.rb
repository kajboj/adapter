require 'adapter_factory'

describe AdapterFactory do
  before(:each) do
    @o = Adaptee.new       
  end

  describe 'initialized without hash' do
    it "just passes messages to adaptee" do
      af = AdapterFactory.new
      
      adapter = af.wrap(@o)

      adapter.hello("Bob").should == "Hello Bob"
      adapter.apply(3) { |x| x*x }.should == 9
      adapter.flat.should == "earth"
    end
  end
  
  describe 'initialized with hash containing only symbols' do
    before(:each) do
      af = AdapterFactory.new(:greetings => :hello)
      @adapter = af.wrap(@o)
    end
    it 'translates messages in the hash' do
      @adapter.greetings("Bob").should == "Hello Bob"
    end
    
    it 'just passes messages not in the hash' do
      @adapter.apply(3) { |x| x*x }.should == 9
    end
  end

  describe 'initialized with hash containing symbols and lambdas' do
    before(:each) do
      af = AdapterFactory.new(
        :not_round => :flat,
        :greetings => :hello,
        :double_apply => lambda { |o, m, a, b| o.apply(o.apply(a.first, &b), &b) }
      )
      @adapter = af.wrap(@o)
    end

    it 'translates messages in the hash' do
      @adapter.double_apply(3) { |x| x*x }.should == 81
    end
    
    it 'just passes messages not in the hash' do
      @adapter.hello("Bob").should == "Hello Bob"
    end
    
    it 'dumps itself into hash containing responses to all messages not requiring parameters in the message hash' do
      @adapter.to_hash.should == {:not_round => "earth"}
    end
  end

  describe 'initialized with hash and block containing method definitions' do
    before(:each) do 
      af = AdapterFactory.new(:not_round => :flat) do
        def double_apply(x, &blk)
          adaptee.apply(
            adaptee.apply(x, &blk), 
            &blk)
        end
      end
      @adapter = af.wrap(@o)
    end

    it 'defines those methods on adapter' do
      @adapter.double_apply(3) { |x| x*x }.should == 81
    end
    
    it 'translates messages in the hash' do
      @adapter.not_round.should == "earth"
    end
  end
  
  describe 'initialized with "always nil"' do
    it 'returns nil in response to the message' do
      af = AdapterFactory.new(:not_round => AdapterFactory::ALWAYS_NIL)
      adapter = af.wrap(@o)
      adapter.not_round.should be_nil 
    end
  end

  describe 'initialized with static value' do
    it 'returns this value in response to the message' do
      af = AdapterFactory.new(:not_round => AdapterFactory::static("pancake"))
      adapter = af.wrap(@o)
      adapter.not_round.should == "pancake"
    end
  end
  
  class Adaptee
    def hello name
      "Hello #{name}"
    end

    def apply(x, &blk)
      yield x if block_given?
    end

    def flat
      "earth"
    end
  end
end
