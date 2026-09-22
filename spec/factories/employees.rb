FactoryBot.define do
  factory :employee do
    sequence(:employee_code) { |n| format('EMP%04d', n) }
    full_name { 'Jane Doe' }
    job_title { 'Software Engineer' }
    department { 'Engineering' }
    country { 'USA' }
    local_salary { 75_000 }
    exchange_rate
  end
end
