module Api
  class TodoListsController < BaseController
    before_action :set_todo_list, only: [:show, :update, :destroy, :complete_all]

    def index
      todo_lists = TodoList.all
      render json: todo_lists
    end

    def show
      render json: @todo_list
    end

    def create
      todo_list = TodoList.create!(todo_list_params)
      render json: todo_list, status: :created
    end

    def update
      @todo_list.update!(todo_list_params)
      render json: @todo_list
    end

    def destroy
      @todo_list.destroy
      head :no_content
    end

    def complete_all
      CompleteAllJob.perform_later(@todo_list)
      render json: { message: 'Complete job in process' }, status: :accepted
    end

    private

    def todo_list_params
      params.require(:todo_list).permit(:name)
    end

    def set_todo_list
      @todo_list = TodoList.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_error('Todo list not found', :not_found)
    end
  end
end
