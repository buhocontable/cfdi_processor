RSpec.describe CfdiProcessor do
  it "has a version number" do
    expect(CfdiProcessor::VERSION).not_to be nil
  end

  it "" do
    expect(CfdiProcessor::StampedExtractor.new(xml_string)).to be_kind_of CfdiProcessor::StampedExtractor
  end
end
