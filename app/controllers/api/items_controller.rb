module Api
  class ItemsController < BaseController
    before_action :set_todo_list
    before_action :set_item, only: [:show, :update, :destroy]

    def index
      @items = @todo_list.items
      render json: @items
    end

    def show
      render json: @item
    end

    def create
      @item = @todo_list.items.build(item_params)
      if @item.save
        render json: @item, status: :created, location: api_todo_list_item_url(@todo_list, @item)
      else
        render_error(@item.errors, :unprocessable_entity)
      end
    end

    def update
      if @item.update(item_params)
        render json: @item
      else
        render_error(@item.errors, :unprocessable_entity)
      end
    end

    def destroy
      @item.destroy
      head :no_content
    end

    private

    def set_todo_list
      @todo_list = TodoList.find(params[:todo_list_id])
    end

    def set_item
      @item = @todo_list.items.find(params[:id])
    end

    def item_params
      params.require(:item).permit(:title, :description, :completed)
    end
  end
end
