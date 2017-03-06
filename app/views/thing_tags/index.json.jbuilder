json.array!(@thing_tags) do |tt|
  json.extract! tt, :id, :thing_id, :tag_id, :created_at, :updated_at
  json.tag_name tt.tag_name  if tt.respond_to?(:tag_name)
end
