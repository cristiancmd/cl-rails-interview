# app/controllers/items_controller.rb
class ItemsController < ApplicationController
  before_action :set_todo_list
  before_action :set_item, only: [:edit, :update, :destroy, :toggle]

  def create
    @item = @todo_list.items.new(item_params)

    respond_to do |format|
      if @item.save
        format.turbo_stream { flash.now[:notice] = "Item creado exitosamente" }
      else
        format.turbo_stream { flash.now[:alert] = "Error: #{@item.errors.full_messages.to_sentence}" }
      end
    end
  end

  def edit; end

  def destroy
    @item.destroy
    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = "Item borrado exitosamente" }
    end
  end

  def toggle
    @item.update(completed: !@item.completed)
    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_todo_list
    @todo_list = TodoList.find(params[:todo_list_id])
  end

  def set_item
    @item = @todo_list.items.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:title, :completed)
  end
end
