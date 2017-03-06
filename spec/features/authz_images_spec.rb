require 'rails_helper'
require_relative '../support/subjects_ui_helper.rb'

RSpec.feature "AuthzImages", type: :feature, js:true do
  include_context "db_cleanup_each"
  include SubjectsUiHelper

  let(:authenticated) { create_user }
  let(:originator)    { create_user }
  let(:organizer)     { originator }
  let(:admin)         { apply_admin create_user }
  let(:image_props)   { FactoryGirl.attributes_for(:image) }
  let(:images)        { FactoryGirl.create_list(:image, 3,
                                                :with_caption,
                                                :with_roles,
                                                :creator_id=>originator[:id])}
  let(:image)         { images[0] }

  shared_examples "can list images" do
    it "lists images" do
      visit_images images
      within("sd-image-selector .image-list") do
        images.each do |img|
          expect(page).to have_css("li a",:text=>img.caption)
          expect(page).to have_css(".image_id",:text=>img.id,:visible=>false)
          expect(page).to have_no_css(".image_id")
        end
      end
    end
  end

  shared_examples "displays correct buttons for role" do |displayed,not_displayed|
    it "displays correct buttons" do
      within("sd-image-editor .image-form") do
        displayed.each do |button|
          disabled_value = ["Update Image"].include? button
          expect(page).to have_button(button,:disabled=>disabled_value)
        end
        not_displayed.each do |button|
          expect(page).to have_no_button(button)
        end
      end
    end
  end
  shared_examples "can create image" do
    it "creates image" do
      within("sd-image-editor .image-form") do
        expect(page).to have_button("Create Image",:wait=>5)
        expect(page).to have_field("image-caption",:readonly=>false)
        fill_in("image-caption", :with=>image_props[:caption])
        expect(page).to have_field("image-caption",:with=>image_props[:caption])
        click_button("Create Image",:disabled=>false,:wait=>5)
        expect(page).to have_button("Clear Image",:wait=>5)
        expect(page).to have_button("Delete Image",:wait=>5)
        expect(page).to have_button("Update Image", :disabled=>true)
        expect(page).to have_no_button("Create Image")
        click_button("Clear Image")
        expect(page).to have_no_button("Clear Image",:wait=>5)
        expect(page).to have_field("image-caption", :with=>"")
        expect(page).to have_button("Create Image")
      end

      #list should now have new value
      within("sd-image-selector .image-list") do
        expect(page).to have_css("li a", :text=>/^#{image_props[:caption]}/, :wait=>5)
      end
    end
  end
  shared_examples "displays image" do
    it "field filled in with clicked image caption" do
      within("sd-image-editor .image-form") do
        expect(page).to have_field("image-caption", :with=>image.caption)
        expect(page).to have_css(".image_id",:text=>image.id,:visible=>false)
        expect(page).to have_no_css(".image_id")
      end
    end
  end
  shared_examples "can clear image" do
    it "image caption cleared from input field" do
      within("sd-image-editor .image-form") do
        #we start out with caption filled in and button(s) displayed
        expect(page).to have_css(".id", :text=>image.id, :visible=>false)
        expect(page).to have_field("image-caption", :with=>image.caption)
        expect(page).to have_no_field("image-caption", :with=>"")
        
        #clear the selected image
        click_button("Clear Image")

        #input field should be cleared
        expect(page).to have_no_field("image-caption", :with=>image.caption)
        expect(page).to have_field("image-caption", :with=>"")
        expect(page).to have_no_button("Clear Image")
        expect(page).to have_no_css(".id", :text=>image.id, :visible=>false)
      end
    end
  end
  shared_examples "cannot update image" do
    it "caption is not updatable" do
      within("sd-image-editor .image-form") do
        #wait for controls to load
        expect(page).to have_button("Clear Image")
        expect(page).to have_field("image-caption", :with=>image.caption, :readonly=>true)
      end
    end
  end

  shared_examples "can update image" do
    it "caption is updated" do
      new_caption="new caption"

      #find(first_link_css).click
      within("sd-image-editor .image-form") do
        #we start out with caption filled in and button(s) displayed
        expect(page).to have_field("image-caption", :with=>image.caption)
        
        #update the input field
        fill_in("image-caption", :with=>new_caption)
        click_button("Update Image")

        #wait for update to initiate before navigating to new page
        expect(page).to have_button("Update Image", :disabled=>true)
        expect(page).to have_field("image-caption", :with=>new_caption)
        5.times do #Clear button does not always go away
          click_button("Clear Image")
          break if page.has_no_button?("Clear Image")
        end
        expect(page).to have_no_button("Clear Image")
        expect(page).to have_field("image-caption", :with=>"")
        expect(page).to have_button("Create Image")
      end

      #list should now have new value
      within("sd-image-selector .image-list") do
        expect(page).to have_css("li a", :text=>/^#{new_caption}/, :wait=>5)
      end
      #verify exists on server after page refresh following logout
      logout
      within("sd-image-selector .image-list") do
        expect(page).to have_css("li a", :text=>/^#{new_caption}/, :wait=>5)
      end
    end
  end
  shared_examples "can delete image" do
    it "image deleted" do
      within("sd-image-editor .image-form") do
        #delete the image
        click_button("Delete Image")

        #wait for delete to initiate before navigating to new page
        expect(page).to have_no_button("Delete Image")
        expect(page).to have_button("Create Image")
      end

      #item should now be gone
      within("sd-image-selector .image-list") do
        expect(page).to have_css("span.image_id",:count=>2,:visible=>false,:wait=>5)
        expect(page).to have_no_css("span.image_id",:text=>image.id,:visible=>false)
      end
    end
  end

  context "no image selected" do
    after(:each) { logout }

    context "unauthenticated user" do
      before(:each) { logout; visit_images images }
      it_behaves_like "can list images" 
      it_behaves_like "displays correct buttons for role", 
            [], 
            ["Create Image", "Clear Image", "Update Image", "Delete Image"]
    end
    context "authenticated user" do
      before(:each) { login authenticated; visit_images images }
      it_behaves_like "can list images" 
      it_behaves_like "displays correct buttons for role", 
            ["Create Image"], 
            ["Clear Image", "Update Image", "Delete Image"]
      it_behaves_like "can create image"
    end
    context "organizer user" do
      before(:each) { login organizer; visit_images images }
      it_behaves_like "displays correct buttons for role", 
            ["Create Image"], 
            ["Clear Image", "Update Image", "Delete Image"]
      it_behaves_like "can create image"
    end
    context "admin user" do
      before(:each) { login admin; visit_images images }
      it_behaves_like "displays correct buttons for role", 
            ["Create Image"], 
            ["Clear Image", "Update Image", "Delete Image"]
      it_behaves_like "can create image"
    end
  end

  context "images posted" do
    before(:each) do
      visit_images images
    end
    after(:each) { logout }

    context "user selects image" do
      before(:each) do
        find("div.image-list .id",:text=>image.id, :visible=>false).find(:xpath,"..").click
      end
      it_behaves_like "displays image"

      context "unauthenticated user" do
        before(:each) { logout }
        it_behaves_like "displays correct buttons for role", 
              ["Clear Image"], 
              ["Create Image", "Update Image", "Delete Image"]
        it_behaves_like "can clear image"
        it_behaves_like "cannot update image"
      end
      context "authenticated user" do
        before(:each) { login authenticated; find(".image-controls") }
        it_behaves_like "displays correct buttons for role",
              ["Clear Image"],
              ["Create Image", "Update Image", "Delete Image"]
        it_behaves_like "can clear image"
        it_behaves_like "cannot update image"
      end
      context "organizer user" do
        before(:each) { login organizer; find(".image-controls > span") }
        it_behaves_like "displays correct buttons for role", 
              ["Clear Image", "Update Image", "Delete Image"],
              ["Create Image"]
        it_behaves_like "can clear image"
        it_behaves_like "can update image"
        it_behaves_like "can delete image"
      end
      context "admin user" do
        before(:each) { login admin; find(".image-controls > span") }
        it_behaves_like "displays correct buttons for role", 
              ["Clear Image", "Delete Image"],
              ["Create Image", "Update Image"]
        it_behaves_like "can clear image"
        it_behaves_like "cannot update image"
        it_behaves_like "can delete image"
      end
    end
  end
end
