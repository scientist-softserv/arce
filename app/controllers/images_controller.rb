require 'iiif/presentation'
require 'open-uri'

class ImagesController < ApplicationController
  include Blacklight::Catalog

  def manifest
    @document = fetch params[:id]
    
    info_json = @document.first.response['docs'].first['resource_url_t']
    preview_url = @document.first.response['docs'].first['resource_preview_t']

    # artefact holds the information you'd find in info.json.
    artefact = JSON.load(open(info_json))
    
    seed = {
      '@id' => artefact['@id'],
      'label' => @document.first.response['docs'].first['title_display']
    }

    # create a "service" resource. 
    service = IIIF::Presentation::Resource.new('@id' => artefact['@id'])
    service['@context'] = "http://iiif.io/api/image/2/context.json"
    service['profile'] = "http://iiif.io/api/image/2/level2.json"

    # Instantiate a new Manifest object.
    manifest = IIIF::Presentation::Manifest.new(seed)

    # Create a thumbnail and add that to the manifest object under the
    # "thumbnail" key.
    #
    # The riiif_image_url gets an absolute URL to the IIIF Image 
    # served by riiif.

    thumbnail = IIIF::Presentation::Resource.new(
        '@id' => preview_url
    )
    thumbnail['@type'] = 'dctypes:Image'
    thumbnail['format'] = 'image/jpeg'

    # Add service variable to the manifest
    thumbnail['service'] = service
    manifest['thumbnail'] = thumbnail

    # IIIF manifest files have fixed structure: 
    #
    #   manifest > sequence > canvas > images > image
    #
    # Create a new sequence and a canvas

    canvas = IIIF::Presentation::Canvas.new()
    sequence = IIIF::Presentation::Sequence.new()

    # A valid IIIF manifest identifies each sequence, canvas, resource,...
    # with an @id that requires a valid HTTP url. The URL could resolve to 
    # that particular sequence fragment served from a remote location. It's
    # not a requirement though, so a random UUID based URL will do.

    sequence['@id'] = "http://" + SecureRandom.uuid
    sequence['@type'] = 'sc:Sequence'
    sequence['label'] = 'Current order'
    sequence['viewingDirection'] = "left-to-right"

    canvas_id = "http://" + SecureRandom.uuid
    canvas['@id'] = canvas_id
    canvas['width'] = artefact['width']
    canvas['height'] = artefact['height']
    canvas['label'] = "Image 1"

    image = IIIF::Presentation::Resource.new('@id' => "http://" + SecureRandom.uuid)
    image['@type'] = 'oa:Annotation'
    image['motivation'] = 'sc:painting'

    # Refers to the canvas associated with this image.
    image['on'] = canvas_id

    # This is the actual image with information from the Image API.
    resource = IIIF::Presentation::Resource.new('@id' => artefact['@id'])
    resource['@type'] = 'dctypes:Image'
    resource['format'] = 'image/jpeg'
    resource['width'] = artefact['width']
    resource['height'] = artefact['height']

    # Combine everything together in one big Ruby variable.
    resource['service'] = service
    image['resource'] = resource
    canvas['images'] = [ image ]
    sequence['canvases'] = [ canvas ]     
    manifest.sequences << sequence
  
    # Render the manifest variable into a valid JSON object to
    # send over HTTP.
    render json: manifest.to_json(pretty: true)

  end
end
