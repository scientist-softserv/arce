# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionsController, type: :controller do

  let(:valid_attributes) {
    { title: 'Collection Title', content: 'Collection Content', video_embed_link: 'Collection Video',
    arts_and_culture_embed: 'Collection Arts and Culture', preview: true }
  }

  let(:invalid_attributes) {
    { bad_attribute: 'Invalid attribute', title: '', video_embed_link: '',
    arts_and_culture_embed: '', preview: '' }
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # CollectionsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #show" do
    it "returns a success response" do
      get :show, params: { id: collection.to_param, collection: valid_attributes }
      expect(response).to be_successful
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: {}, session: valid_session
      expect(response).to be_successful
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      get :edit, params: { id: collection.to_param }, session: valid_session
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Collection" do
        expect { post :create, params: { collection: valid_attributes },
        session: valid_session }.to change(Collection, :count).by(1)
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
      let(:new_attributes) {
        { title: "My New Collection Title", content: 'Collection Content', video_embed_link: 'Collection Video',
        arts_and_culture_embed: 'Collection Arts and Culture', preview: true }
      }

      it "updates the requested collection" do
        put :update, params: { id: collection.to_param, collection: new_attributes }, session: valid_session
        collection.reload
        if collection.valid?
          expect(response).to be_successful
        end
      end

      it "redirects to the collection" do
        put :update, params: { id: collection.to_param, collection: valid_attributes }, session: valid_session
        expect(response).to redirect_to(collection)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
        put :update, params: { id: collection.to_param, collection: invalid_attributes }, session: valid_session
        expect(response).to be_successful
      end
    end
  end

  describe "DELETE #destroy" do
      it "destroys the requested collection" do
        expect { delete :destroy, params: { id: collection.to_param, collection: valid_attributes },
        session: valid_session }.to change(Collection, :count).by(-1)
      end

      it "redirects to the admin index page" do
        delete :destroy, params: { id: collection.to_param, collection: valid_attributes }, session: valid_session
        expect(response).to redirect_to(admin_path)
      end
  end

end
