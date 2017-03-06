class Thing < ActiveRecord::Base
  include Protectable
  validates :name, :presence=>true

  has_many :thing_images, inverse_of: :thing, dependent: :destroy

  scope :not_linked, ->(image) { where.not(:id=>ThingImage.select(:thing_id)
                                                          .where(:image=>image)) }
  # Tags
  has_many :thing_tags, inverse_of: :thing, dependent: :destroy
  has_many :tags, through: :thing_tags

  scope :with_tag, ->(tag) {where(id: ThingTag.select(:thing_id).where(tag: tag))}
  scope :without_tag, ->(tag) { where.not(id: ThingTag.select(:thing_id).where(tag: tag)) }
  scope :just_the_name, -> {unscope(:select).select("things.id, name AS thing_name")}

end
