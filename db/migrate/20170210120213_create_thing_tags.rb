class CreateThingTags < ActiveRecord::Migration
  def change
    create_table :thing_tags do |t|
      t.references :thing, index: true, foreign_key: true
      t.references :tag, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
