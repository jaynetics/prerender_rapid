require 'spec_helper'

describe Rack::Prerender do
  let(:prerender)  { Rack::Prerender.new(app) }
  let(:app)        { ->*{ [200, {}, 'live_body'] } }
  let(:constraint) { prerender.constraint }
  let(:fetcher)    { prerender.fetcher }

  it 'has a VERSION number' do
    expect(Rack::Prerender::VERSION).not_to be_nil
  end

  describe '#call' do
    context 'if the constraint does not match' do
      before { allow(constraint).to receive(:matches?).and_return false }

      it 'does not call the fetcher' do
        expect(fetcher).not_to receive(:call)
        prerender.call({})
      end

      it 'falls through' do
        expect(app).to receive(:call).and_return :live_page
        expect(prerender.call({})).to eq :live_page
      end
    end

    context 'if the constraint matches' do
      before { allow(constraint).to receive(:matches?).and_return true }

      it 'calls the fetcher' do
        expect(fetcher).to receive(:call)
        prerender.call({})
      end

      it 'exits with the fetcher result if there is one' do
        expect(fetcher).to receive(:call).and_return :cached_page
        expect(app).not_to receive(:call)
        expect(prerender.call({})).to eq :cached_page
      end

      it 'falls through if the fetcher returns nothing' do
        expect(fetcher).to receive(:call).and_return nil
        expect(app).to receive(:call).and_return :live_page
        expect(prerender.call({})).to eq :live_page
      end
    end
  end
end
