# frozen_string_literal: true

require 'faker'

200.times do
  Project.create(
    name: Faker::App.name,
    description: Faker::Lorem.paragraph,
    status: %w[planned ongoing completed].sample,
    priority: %w[low medium high].sample,
    start_date: Faker::Date.between(from: 2.years.ago, to: Date.today),
    end_date: Faker::Date.between(from: Date.today, to: 2.years.from_now),
    created_at: Time.now,
    updated_at: Time.now
  )
end

puts "200 projects have been created successfully!"


