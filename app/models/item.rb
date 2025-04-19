class Item < ApplicationRecord
  belongs_to :todo_list
  validates :title, presence: true

  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: false) }

  validates :title, length: { maximum: 250 }
  after_update_commit { broadcast_replace_to self }
end
