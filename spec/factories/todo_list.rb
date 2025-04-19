FactoryBot.define do
  factory :todo_list do
    name { Faker::Lorem.sentence[0..10] }
  end
end
