# frozen_string_literal: true

class CollectionsController < ApplicationController
  before_action :set_collection, only: %i[show edit update destroy]
  before_action :herd_user, only: %i[new edit update destroy]

  # GET /collections/1
  # GET /collections/1.json
  def show
    if @collection.private?
      redirect_to root_path, notice: "Collection not avaliable" unless current_user && !current_user.guest
    else
      @collection = Collection.friendly.find(params[:id])
    end
  end

  # GET /collections/new
  def new
    @collection = Collection.new
    @collection.gac_embeds.build
    @collection.video_links.build
  end

  # GET /collections/1/edit
  def edit
    @collection.gac_embeds.build
    @collection.video_links.build
  end

  # POST /collections
  # POST /collections.json
  def create
    @collection = Collection.new(collection_params)

    respond_to do |format|
      if @collection.save
        format.html { redirect_to @collection, notice: 'Collection was successfully created.' }
        format.json { render :show, status: :created, location: @collection }
      else
        format.html { render :new }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /collections/1
  # PATCH/PUT /collections/1.json
  def update
    respond_to do |format|
      if @collection.update(collection_params)
        format.html { redirect_to @collection, notice: 'Collection was successfully updated.' }
        format.json { render :show, status: :ok, location: @collection }
      else
        format.html { render :edit }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /collections/1
  # DELETE /collections/1.json
  def destroy
    @collection.destroy
    respond_to do |format|
      format.html { redirect_to admin_path, notice: 'Collection was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    def set_collection
      @collection = Collection.friendly.find(params[:id])
    end

    # rubocop:disable Style/SymbolArray
    # Never trust parameters from the scary internet, only allow the white list through.
    def collection_params
      params.require(:collection).permit(:title, :content, :banner_image, :video_embed_link, :image,
                                         :remote_image_url, :private, :remove_banner_image, :remove_image,
                                         gac_embeds_attributes: [:id, :title, :embed, :_destroy],
                                         video_links_attributes: [:id, :title, :link, :_destroy])
    end
  # rubocop:enable Style/SymbolArray
end
