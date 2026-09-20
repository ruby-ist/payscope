FactoryBot.define do
  factory :exchange_rate do
    sequence(:currency) { |n| (0..2).map { |i| ((n / (26**i)) % 26 + 65).chr }.reverse.join }
    rate { 1.5 }
  end
end
