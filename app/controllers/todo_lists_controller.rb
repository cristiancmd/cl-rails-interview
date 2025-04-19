class TodoListsController < ApplicationController
  before_action :set_todo_list, only: [:show, :destroy, :complete_all]

  def index
    @todo_lists = TodoList.order(created_at: :desc)
    @todo_list = TodoList.new
  end

  def show
    @item = Item.new
  end

  def create
    @todo_list = TodoList.new(todo_list_params)

    respond_to do |format|
      if @todo_list.save
        format.turbo_stream { flash.now[:notice] = "Lista creada exitosamente" }
      else
        format.turbo_stream { flash.now[:alert] = "Error al crear la lista: #{@todo_list.errors.full_messages.to_sentence}" }
      end
    end
  end

  def edit ; end

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
