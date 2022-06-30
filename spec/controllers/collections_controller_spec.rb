# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionsController, type: :controller do
  let(:valid_attributes) do
    { title: 'Collection Title', content: 'Collection Content', video_embed_link: 'Collection Video', private: true }
  end

  let(:invalid_attributes) do
    { bad_attribute: 'Invalid attribute', title: '', video_embed_link: '',
      private: '' }
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # CollectionsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  let(:user) do
    User.create(
      email: 'test@testing.com',
      guest: false
    )
  end

  describe "GET #show" do
    it "returns a success response" do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      collection = Collection.create(valid_attributes)
      get :show, params: { id: collection.to_param, collection: valid_attributes }
      expect(response).to be_successful
    end

    it "returns an unsuccesful response for private collections" do
      collection = Collection.create(valid_attributes)
      get :show, params: { id: collection.to_param, collection: valid_attributes }
      expect(response).not_to be_successful
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      get :new, params: {}, session: valid_session
      expect(response).to be_successful
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      collection = Collection.create(valid_attributes)
      get :edit, params: { id: collection.id }, session: valid_session
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Collection" do
        expect do
          post :create, params: { collection: valid_attributes },
                        session: valid_session
        end.to change(Collection, :count).by(1)
      end

      it "redirects to the created collection" do
        post :create, params: { collection: valid_attributes }, session: valid_session
        expect(response).to redirect_to(Collection.last)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: { collection: invalid_attributes }, session: valid_session
        expect(response).to be_successful
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      it "redirects to the collection after update" do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        collection = Collection.create(valid_attributes)
        patch :update,
              params: { id: collection.id, collection: { title: "New Collection Name" } },
              session: valid_session
        collection.reload
        expect(response).to redirect_to(collection)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        collection = Collection.create(valid_attributes)
        put :update, params: { id: collection.to_param, collection: invalid_attributes }, session: valid_session
        expect(response).to be_successful
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested collection" do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      collection = Collection.create(valid_attributes)
      expect do
        delete :destroy, params: { id: collection.to_param, collection: valid_attributes },
                         session: valid_session
      end.to change(Collection, :count).by(-1)
    end

    it "redirects to the admin index page" do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      collection = Collection.create(valid_attributes)
      delete :destroy, params: { id: collection.to_param, collection: valid_attributes }, session: valid_session
      expect(response).to redirect_to(admin_path)
    end
  end
end
