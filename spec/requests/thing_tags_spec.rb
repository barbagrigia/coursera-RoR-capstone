require 'rails_helper'

RSpec.describe "ThingTags", type: :request do
  include_context "db_cleanup_each"
  #originator becomes organizer after creation
  let(:originator) { apply_originator(signup(FactoryGirl.attributes_for(:user)), Thing) }
  let(:tag) {FactoryGirl.create(:tag)}

  describe "manage thing/tag relationships" do
    let!(:user) { login originator }
    context "valid thing and tag" do
      let(:thing) { create_resource(things_path, :thing, :created) }
      let(:thing_tag_props) {
        FactoryGirl.attributes_for(:thing_tag, :tag_id=>tag["id"])
      }

      it "can associate tag with thing" do
        #associated the tag to the Thing
        jpost thing_thing_tags_path(thing["id"]), thing_tag_props
        expect(response).to have_http_status(:no_content)

        #get Thingtags for Thing and verify associated with tag
        jget thing_thing_tags_path(thing["id"])
        expect(response).to have_http_status(:ok)
        #puts response.body
        payload=parsed_body
        expect(payload.size).to eq(1)
        expect(payload[0]).to include("tag_id"=>tag["id"])
        expect(payload[0]).to include("tag_name"=>tag["name"])
      end

      it "must have tag" do
        jpost thing_thing_tags_path(thing["id"]), thing_tag_props.except(:tag_id)
        expect(response).to have_http_status(:bad_request)
        payload=parsed_body
        expect(payload).to include("errors")
        expect(payload["errors"]["full_messages"]).to include(/param/,/missing/)
      end
    end
  end

  shared_examples "can get links" do
    it "can get tags of Thing" do
      jget thing_thing_tags_path(linked_thing_id)
      expect(response).to have_http_status(:ok)
      expect(parsed_body.size).to eq(linked_tag_ids.count)
      expect(parsed_body[0]).to include("tag_name")
      expect(parsed_body[0]).to_not include("thing_name")
    end
    it "can get things with tag" do
      jget tag_associated_things_path(linked_tag_id)
      expect(response).to have_http_status(:ok)
      expect(parsed_body.size).to eq(1)
      expect(parsed_body[0]).to_not include("tag_name")
      expect(parsed_body[0]).to include("thing_name"=>linked_thing["name"])
    end
  end
  shared_examples "get linkables" do |count, user_roles=[]|
    it "return linkable things" do
      jget tag_linkable_things_path(linked_tag_ids[0])
      #pp parsed_body
      expect(response).to have_http_status(:ok)
      expect(parsed_body.size).to eq(count)
      if (count > 0)
          parsed_body.each do |thing|
            expect(thing["id"]).to be_in(unlinked_thing_ids)
            expect(thing).to include("thing_name")
            expect(thing).to_not include("description")
          end
      end
    end
  end
  shared_examples "can create link" do
    it "link from Thing to tag" do
      jpost thing_thing_tags_path(linked_thing_id), thing_tag_props
      expect(response).to have_http_status(:no_content)
      jget thing_thing_tags_path(linked_thing_id)
      expect(parsed_body.size).to eq(linked_tag_ids.count+1)
    end
    it "link from tag to Thing" do
      jpost tag_associated_things_path(thing_tag_props[:tag_id]),
                                    thing_tag_props.merge(:thing_id=>linked_thing_id)
      expect(response).to have_http_status(:no_content)
      jget thing_thing_tags_path(linked_thing_id)
      expect(parsed_body.size).to eq(linked_tag_ids.count+1)
    end
    it "bad request when link to unknown tag" do
      jpost thing_thing_tags_path(linked_thing_id),
                                    thing_tag_props.merge(:tag_id=>99999)
      expect(response).to have_http_status(:bad_request)
    end
    it "bad request when link to unknown Thing" do
      jpost tag_associated_things_path(thing_tag_props[:tag_id]),
                                    thing_tag_props.merge(:thing_id=>99999)
      expect(response).to have_http_status(:bad_request)
    end
  end
  shared_examples "can update link" do
    it do
      jput thing_thing_tag_path(thing_tag["thing_id"], thing_tag["id"]),
                             thing_tag.merge("priority"=>0)
      expect(response).to have_http_status(:no_content)
    end
  end
  shared_examples "can delete link" do
    it do
      jdelete thing_thing_tag_path(thing_tag["thing_id"], thing_tag["id"])
      expect(response).to have_http_status(:no_content)
    end
  end
  shared_examples "cannot create link" do |status|
    it do
      jpost thing_thing_tags_path(linked_thing_id), thing_tag_props
      expect(response).to have_http_status(status)
    end
  end
  shared_examples "cannot update link" do |status|
    it do
      jput thing_thing_tag_path(thing_tag["thing_id"], thing_tag["id"]),
                             thing_tag.merge("priority"=>0)
      expect(response).to have_http_status(status)
    end
  end
  shared_examples "cannot delete link" do |status|
    it do
      jdelete thing_thing_tag_path(thing_tag["thing_id"], thing_tag["id"])
      expect(response).to have_http_status(status)
    end
  end


  describe "Thingtag Authn policies" do
    let(:account)         { signup FactoryGirl.attributes_for(:user) }
    let(:thing_resources) { 3.times.map { create_resource(things_path, :thing, :created) } }
    let(:tag_resources) { 4.times.map { FactoryGirl.create(:tag) } }
    let(:things)          { thing_resources.map {|t| Thing.find(t["id"]) } }
    let(:linked_thing)    { things[0] }
    let(:linked_thing_id) { linked_thing.id }
    let(:linked_tag_ids)  { (0..2).map {|idx| tag_resources[idx]["id"] } }
    let(:unlinked_thing_ids){ (1..2).map {|idx| thing_resources[idx]["id"] } }
    let(:linked_tag_id)   { tag_resources[0]["id"] }
    let(:orphan_tag_id)   { tag_resources[3]["id"] }     #unlinked tag to link to thing
    let(:thing_tag_props) { { :tag_id=>orphan_tag_id } } #payload required to link tag
    let(:thing_tag)       { #return existing thing so we can modify
      jget thing_thing_tags_path(linked_thing_id)
      expect(response).to have_http_status(:ok)
      parsed_body[0]
    }
    before(:each) do
      login originator
      thing_resources
      tag_resources
      linked_tag_ids.each do |tag_id| #link thing and tags, leave orphans
        jpost thing_thing_tags_path(linked_thing_id), {:tag_id=>tag_id}
        expect(response).to have_http_status(:no_content)
      end
    end

    context "user is anonymous (tag)" do
      before(:each) { logout }
      it_should_behave_like "can get links"
      it_should_behave_like "get linkables", 0
      it_should_behave_like "cannot create link", :unauthorized
      it_should_behave_like "cannot update link", :unauthorized
      it_should_behave_like "cannot delete link", :unauthorized
    end
    context "user is authenticated (tag)" do
      before(:each) { login account }
      it_should_behave_like "can get links"
      it_should_behave_like "get linkables", 0
      it_should_behave_like "cannot create link", :forbidden
      it_should_behave_like "cannot update link", :forbidden
      it_should_behave_like "cannot delete link", :forbidden
    end
    context "user is member (tag)" do
      before(:each) do
        login apply_member(account, things)
      end
      it_should_behave_like "can get links"
      it_should_behave_like "get linkables", 2, [Role::MEMBER]
      it_should_behave_like "cannot create link", :forbidden
      it_should_behave_like "cannot update link", :forbidden
      it_should_behave_like "cannot delete link", :forbidden
    end
    context "user is organizer (tag)" do
      it_should_behave_like "can get links"
      it_should_behave_like "get linkables", 2, [Role::ORGANIZER]
      it_should_behave_like "can create link"
      it_should_behave_like "can update link"
      it_should_behave_like "can delete link"
    end
    context "user is admin (tag)" do
      before(:each) { login apply_admin(account) }
      it_should_behave_like "can get links"
      it_should_behave_like "get linkables", 0
      it_should_behave_like "cannot create link", :forbidden
      it_should_behave_like "cannot update link", :forbidden
      it_should_behave_like "can delete link"
    end
  end
end
