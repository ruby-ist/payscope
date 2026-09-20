FactoryBot.define do
  factory :employee do
    sequence(:employee_code) { |n| "EMP#{n}" }
    full_name { 'Jane Doe' }
    job_title { 'Software Engineer' }
    department { 'Engineering' }
    country { 'USA' }
    local_salary { 75_000 }
    association :exchange_rate
  end
end
