require "spec_helper"

module RSpec::Core::Ordering
  describe Identity do
    it "does not affect the ordering of the items" do
      expect(Identity.new.order([1, 2, 3])).to eq([1, 2, 3])
    end

    it 'is considered a built in ordering' do
      expect(Identity.new).to be_built_in
    end
  end

  describe Random do
    before { allow(Kernel).to receive(:srand).and_call_original }

    def order_of(input, seed)
      Kernel.srand(seed)
      input.shuffle
    end

    it 'shuffles the items randomly' do
      configuration = RSpec::Core::Configuration.new
      configuration.seed = 900

      expected = order_of([1, 2, 3, 4], 900)

      strategy = Random.new
      expect(strategy.order([1, 2, 3, 4], configuration)).to eq(expected)
    end

    it 'seeds the random number generator' do
      expect(Kernel).to receive(:srand).with(1234).once

      configuration = RSpec::Core::Configuration.new
      configuration.seed = 1234

      strategy = Random.new
      strategy.order([1, 2, 3, 4], configuration)
    end

    it 'resets random number generation' do
      expect(Kernel).to receive(:srand).with(no_args)

      strategy = Random.new
      strategy.order([])
    end

    it 'is considered a built in ordering' do
      expect(Random.new).to be_built_in
    end
  end

  describe Custom do
    it 'uses the block to order the list' do
      strategy = Custom.new(proc { |list| list.reverse })

      expect(strategy.order([1, 2, 3, 4])).to eq([4, 3, 2, 1])
    end

    it 'is not considered a built in ordering' do
      expect(Custom.new(proc { })).not_to be_built_in
    end
  end

  describe Registry do
    let(:configuration) { double("configuration") }
    subject { Registry.new(configuration) }

    describe "#[]" do
      it "gives the default ordering when given nil" do
        expect(subject[nil]).to be_an_instance_of(Identity)
      end

      it "gives a callable ordering when called with a callable" do
        expect(subject[proc { :hi }]).to be_a_kind_of(Custom)
      end

      it "gives the registered ordering when called with a symbol" do
        ordering = Object.new
        subject.register(:falcon, ordering)

        expect(subject[:falcon]).to be ordering
      end

      it "gives me the global one when I call it with an unknown symbol" do
        expect(subject[:falcon]).to be_an_instance_of(Identity)
      end
    end
  end
end
