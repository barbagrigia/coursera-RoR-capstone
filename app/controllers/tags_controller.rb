class TagsController < ApplicationController
  before_action :set_tag, only: [:show, :update, :destroy]
  before_action :authenticate_user!, only: [:create, :update, :destroy]
  after_action :verify_authorized
  wrap_parameters :tag, include: ["name"]

  def index
    authorize Tag
    @tags = Tag.all
    render json: @tags
  end

  def show
    authorize Tag
    render json: @tag
  end

  def create
    authorize Tag
    @tag = Tag.new(tag_params)

    if @tag.save
      render json: @tag, status: :created, location: @tag
    else
      render json: @tag.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize Tag
    @tag = Tag.find(params[:id])

    if @tag.update(tag_params)
      head :no_content
    else
      render json: @tag.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize Tag
    @tag.destroy

    head :no_content
  end

  private

    def set_tag
      @tag = Tag.find(params[:id])
    end

    def tag_params
      params.require(:tag).permit(:name)
    end
end
