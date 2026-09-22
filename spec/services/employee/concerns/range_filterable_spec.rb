require 'rails_helper'

RSpec.shared_examples 'a range filter' do |attribute, invalid_bound:|
  context 'with only a minimum' do
    let(:bounds) do
      minimum = records.sort_by { |record| record.public_send(attribute) }[1].public_send(attribute)
      { from: minimum, to: nil }
    end

    it 'includes records at or above the boundary' do
      minimum = records.sort_by { |record| record.public_send(attribute) }[1].public_send(attribute)
      expected = records.select { |record| record.public_send(attribute) >= minimum }

      expect(filtered_value).to match_array(expected)
    end
  end

  context 'with only a maximum' do
    let(:bounds) do
      maximum = records.sort_by { |record| record.public_send(attribute) }[1].public_send(attribute)
      { from: nil, to: maximum }
    end

    it 'includes records at or below the boundary' do
      maximum = records.sort_by { |record| record.public_send(attribute) }[1].public_send(attribute)
      expected = records.select { |record| record.public_send(attribute) <= maximum }

      expect(filtered_value).to match_array(expected)
    end
  end

  context 'with both bounds' do
    let(:bounds) do
      minimum, maximum = records.sort_by { |record| record.public_send(attribute) }
                                 .first(2).map { |record| record.public_send(attribute) }
      { from: minimum, to: maximum }
    end

    it 'returns records inside the range' do
      minimum, maximum = records.sort_by { |record| record.public_send(attribute) }
                                 .first(2).map { |record| record.public_send(attribute) }
      expected = records.select { |record| record.public_send(attribute).between?(minimum, maximum) }

      expect(filtered_value).to match_array(expected)
    end
  end

  context 'with an unparseable bound' do
    let(:bounds) { { from: invalid_bound, to: nil } }

    it 'ignores the bound rather than filtering everything out' do
      expect(filtered_value).to match_array(records)
    end
  end

  context 'when both bounds are blank' do
    let(:bounds) { { from: '', to: '' } }

    it 'returns every record' do
      expect(filtered_value).to match_array(records)
    end
  end
end
