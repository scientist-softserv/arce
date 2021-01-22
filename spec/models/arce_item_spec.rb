require 'rails_helper'

describe ArceItem do
  it 'gets the client' do
    client = ArceItem.client({url: 'http://www.example.com'})
    expect(client.as_json['http_client']['url_prefix']).to eq 'http://www.example.com/'
  end

  it 'can import item' do
    expected_imported = 2
    total_imported = ArceItem.import({limit: expected_imported})
    expect(total_imported).to eq expected_imported
  end

  skip it 'does not reimport duplicate records' do 
    # it is possible that this may give a false negative due to sorting of records
    total_imported = ArceItem.import({progress: false, limit: 1})
    expect(total_imported).to eq 1
    document_id = ArceItem.fetch_first_id
    record = ArceItem.find_or_new(document_id)
    expect(record.new_record?).to eq false
  end

  skip it 'can import a specific single item' do 
    document_id = ArceItem.fetch_first_id
    imported_record = ArceItem.import_single(document_id)
    expect(imported_record.id).to match document_id
  end
end
