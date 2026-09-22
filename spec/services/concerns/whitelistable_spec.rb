require 'rails_helper'

RSpec.describe Whitelistable do
  subject(:whitelisted) { includer.send(:whitelisted, value, allowed, fallback) }

  let(:includer) { Class.new { include Whitelistable }.new }
  let(:allowed) { %w[asc desc] }
  let(:fallback) { 'asc' }

  context 'when the value is in the allowed list' do
    let(:value) { 'desc' }

    it 'returns the value' do
      expect(whitelisted).to eq('desc')
    end
  end

  context 'when the value is not in the allowed list' do
    let(:value) { 'sideways' }

    it 'returns the fallback' do
      expect(whitelisted).to eq('asc')
    end
  end

  context 'when the value is nil' do
    let(:value) { nil }

    it 'returns the fallback' do
      expect(whitelisted).to eq('asc')
    end
  end
end
