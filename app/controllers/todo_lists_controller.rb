class TodoListsController < ApplicationController
  before_action :set_todo_list, only: [:show, :edit, :update, :destroy, :complete_all]

  def index
    @todo_lists = TodoList.order(created_at: :desc)
    @todo_list = TodoList.new
  end

  def show
    @item = Item.new
  end

  def create
    @todo_list = TodoList.new(todo_list_params)

    if @todo_list.save
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = "Lista creada exitosamente" }
      end
    else
      render :index, status: :unprocessable_entity
    end
  end

  def edit
    render partial: "form", locals: { todo_list: @todo_list }
  end

  def destroy
    @todo_list.destroy
    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = "Lista eliminada exitosamente" }
    end
  end

  def complete_all
    CompleteAllJob.perform_later(@todo_list)
    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = "Completando tareas" }
    end
  end

  private

  def set_todo_list
    @todo_list = TodoList.find(params[:id])
  end

  def todo_list_params
    params.require(:todo_list).permit(:name)
  end
end
