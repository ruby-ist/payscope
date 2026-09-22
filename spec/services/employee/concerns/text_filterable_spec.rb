require 'rails_helper'

RSpec.shared_examples 'a text filter' do |attribute, matching_term:|
  context 'when it partially matches' do
    let(:term) { matching_term }

    it 'returns the matching records' do
      expected = records.select { |record| record.public_send(attribute).to_s.downcase.include?(term.downcase) }

      expect(filtered_value).to match_array(expected)
    end
  end

  context 'when the case differs' do
    let(:term) { matching_term.swapcase }

    it 'matches case-insensitively' do
      expected = records.select { |record| record.public_send(attribute).to_s.downcase.include?(matching_term.downcase) }

      expect(filtered_value).to match_array(expected)
    end
  end

  context 'when nothing matches' do
    let(:term) { 'Definitely Not A Match 12345' }

    it 'returns nothing' do
      expect(filtered_value).to be_empty
    end
  end

  context 'when the term contains a LIKE wildcard' do
    let(:term) { '%' }

    it 'treats the wildcard as a literal character' do
      expect(filtered_value).to be_empty
    end
  end

  context 'when the term is blank' do
    let(:term) { '' }

    it 'returns every record' do
      expect(filtered_value).to match_array(records)
    end
  end
end
