class ThingTag < ActiveRecord::Base
  belongs_to :thing
  belongs_to :tag

  validates :tag_id, :thing_id, presence: true
  scope :with_name, ->{ joins(:tag).select("thing_tags.*, tags.name AS tag_name")}
end
