class TodoList < ApplicationRecord
  has_many :items, dependent: :destroy
  validates :name, presence: true

  default_scope { order(created_at: :desc) }

end
