class CompleteAllJob < ApplicationJob
  queue_as :default

  def perform(todo_list)
    todo_list.items.update(completed: true) # update_all won't trigger callbacks so we use update
  end
end
