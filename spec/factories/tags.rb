FactoryGirl.define do
  factory :tag do
    name Faker::Commerce.department(1)
  end
end
