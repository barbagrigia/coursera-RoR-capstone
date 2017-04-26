class ImagesController < ApplicationController
  before_action :set_image, only: [:show, :update, :destroy, :content]
  wrap_parameters :image, include: ["caption", "position"]
  before_action :authenticate_user!, only: [:create, :update, :destroy]
  after_action :verify_authorized, except: [:content]
  after_action :verify_policy_scoped, only: [:index]

  rescue_from EXIFR::MalformedJPEG, with: :contents_error

  def index
    authorize Image
    @images = policy_scope(Image.all)
    @images = ImagePolicy.merge(@images)
  end

  def show
    authorize @image
    images = policy_scope(Image.where(:id=>@image.id))
    @image = ImagePolicy.merge(images).first
  end

  def content
    result=ImageContent.image(@image).smallest(params[:width],params[:height]).first
    if result
      expires_in 1.year, :public=>true 
      if stale? result
        options = { type: result.content_type,
                    disposition: "inline",
                    filename: "#{@image.basename}.#{result.suffix}" }
        send_data result.content.data, options
      end
    else
      render nothing: true, status: :not_found
    end
  end

  def create
    authorize Image
    @image = Image.new(image_params)
    @image.creator_id=current_user.id

    User.transaction do
      if @image.save
        original=ImageContent.new(image_content_params)
        contents=ImageContentCreator.new(@image, original).build_contents
        if (contents.save!) 
          role=current_user.add_role(Role::ORGANIZER, @image)
          @image.user_roles << role.role_name
          role.save!
          render :show, status: :created, location: @image
        end
      else
        render json: {errors:@image.errors.messages}, status: :unprocessable_entity
      end
    end
  end

  def update
    authorize @image

    if @image.update(image_params)
      head :no_content
    else
      render json: {errors:@image.errors.messages}, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @image
    ImageContent.image(@image).delete_all
    @image.destroy

    head :no_content
  end

  private

    def set_image
      @image = Image.find(params[:id])
    end

    def image_params
      params.require(:image).permit(:caption,:position=>[:lng,:lat])
    end

    def image_content_params
      params.require(:image_content).tap { |ic|
        ic.require(:content_type)
        ic.require(:content)
      }.permit(:content_type, :content)
    end

    def contents_error exception
      render json: {errors:{full_messages:["unable to create image contents","#{exception}"]}},
            status: :unprocessable_entity
      Rails.logger.debug exception
    end

    def mongoid_validation_error(exception) 
      payload = { errors:exception.record.errors.messages
                     .slice(:content_type,:content,:full_messages) 
                     .merge(full_messages:["unable to create image contents"])}
      render :json=>payload, :status=>:unprocessable_entity
      Rails.logger.debug exception.message
    end
end
