class ThingTagsController < ApplicationController
  before_action :authenticate_user!, only: [:create, :update, :destroy]
  before_action :set_thing_tag, only: [:show, :update, :destroy]
  before_action :set_tag, only: [:associated_things, :linkable_things]
  before_action :set_thing, only: [:index, :destroy, :update]
  wrap_parameters :thing_tag, include: ["tag_id", "thing_id"]

  after_action :verify_authorized

  def index
    authorize @thing, :get_tags?
    @thing_tags = ThingTag.where(thing_id: params["thing_id"]).with_name
  end

  def show
    authorize @thing, :get_tags?
    render json: @thing_tag
  end

  def create
    link_params = thing_tag_params.merge({thing_id: params[:thing_id], tag_id: params[:tag_id]})
    @thing_tag = ThingTag.new(link_params)
    @thing = Thing.where(id: @thing_tag.thing_id).first
    @tag = Tag.where(id: @thing_tag.tag_id).first
    # Check tag and thing exist
    if ! @tag
      render json: {errors: "Cannot find tag #{@thing_tag.tag_id}"}, status: :bad_request
      skip_authorization
    elsif ! @thing
      render json: {errors: "Cannot find thing #{@thing_tag.thing_id}"}, status: :bad_request
      skip_authorization
    else
      authorize @thing, :add_tag?
      if @thing_tag.save
        head :no_content
      else
        pp @thing_tag.errors.messages
        render json: {errors:@thing_tag.errors.messages}, status: :unprocessable_entity
        skip_authorization
      end
    end
  end

  def update
    authorize @thing, :update_tag?
    @thing_tag = ThingTag.find(params[:id])

    if @thing_tag.update(thing_tag_params)
      head :no_content
    else
      render json: @thing_tag.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @thing, :remove_tag?
    @thing_tag.destroy
    head :no_content
  end

  def associated_things
    authorize Thing, :get_tags?
    render json: Thing.with_tag(@tag).just_the_name
  end

  def linkable_things
    authorize Thing, :get_linkables?
    render json: ThingPolicy::Scope.new(current_user, Thing.all).user_roles(true, false).just_the_name.without_tag(@tag)
  end

  private

    def set_thing_tag
      @thing_tag = ThingTag.find(params[:id])
    end

    def set_tag
      @tag = Tag.find(params[:tag_id])
    end

    def set_thing
      @thing = Thing.find(params[:thing_id])
    end

    def thing_tag_params
      params.require(:thing_tag).tap {|p|
        #_ids only required in payload when not part of URI
        p.require(:tag_id)    if !params[:tag_id]
        p.require(:thing_id)    if !params[:thing_id]
      }.permit(:tag_id, :thing_id)
    end
end
