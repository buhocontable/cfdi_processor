RSpec.describe CfdiProcessor::StampedExtractor do
  subject { CfdiProcessor::StampedExtractor.new(xml_string) }

  it { is_expected.to respond_to(:xml) }
  it { is_expected.to respond_to(:nokogiri_xml) }
  it { is_expected.to respond_to(:receipt) }
  it { is_expected.to respond_to(:issuer) }
  it { is_expected.to respond_to(:receiver) }
  it { is_expected.to respond_to(:concepts) }
  it { is_expected.to respond_to(:taxes) }
  it { is_expected.to respond_to(:global_info) }

  describe '#xml' do
    it 'is expected that return a kind of String' do
      expect(subject.xml).to be_kind_of String
    end
  end

  describe '#nokogiri_xml' do
    it 'is expected that return a kind of Nokogiri::XML::Document' do
      expect(subject.nokogiri_xml).to be_kind_of Nokogiri::XML::Document
    end
  end

  describe '#extract_data_from_xml' do
    it 'is expected that return CfdiProcessor::StampedExtractor' do
      expect(subject.extract_data_from_xml).to be_kind_of CfdiProcessor::StampedExtractor
    end
  end

  describe '#translate_data' do
    before do
      subject.extract_data_from_xml
    end

    before do
      subject.translate_data
    end

    it 'is expected that return CfdiProcessor::StampedExtractor' do
      expect(subject.translate_data).to be_kind_of CfdiProcessor::StampedExtractor
    end

    it 'is expected that return @receipt translated' do
      expect(subject.receipt.include?('date_issued')).to be_truthy
    end
  end

  context 'when it has global_info' do
    subject { CfdiProcessor::StampedExtractor.new(xml_with_global_info) }

    describe '#extract_data_from_xml' do
      it 'contains global_info data' do
        expect(subject.global_info).to be_present
        expect(subject.global_info['periodicity']).to eql('04')
        expect(subject.global_info['month']).to eql('02')
        expect(subject.global_info['year']).to eql('2023')
      end
    end
  end

  context 'when it has totals attrs in taxes data' do
    subject { CfdiProcessor::StampedExtractor.new(xml_with_global_info) }

    describe '#extract_data_from_xml' do
      it 'contains taxes data' do
        expect(subject.taxes['total_taxes_transferred']).to be_present
        expect(subject.taxes['total_taxes_detained']).to be_present
      end
    end
  end

  context "when the Addenda contains an element named 'Impuestos' in a private namespace" do
    subject { CfdiProcessor::StampedExtractor.new(xml_with_impuestos_in_addenda) }

    it 'picks the top-level Impuestos, not the one inside the Addenda' do
      expect(subject.taxes['total_taxes_transferred']).to eql('30.62')
    end

    it 'extracts the real top-level traslados, not Addenda children' do
      transferred = subject.taxes['transferred']
      expect(transferred.size).to eql(2)
      rated = transferred.find { |t| t['rate_or_fee'] == '0.160000' }
      expect(rated['import']).to eql('30.62')
      expect(rated['base']).to eql('191.38')
    end
  end

  context 'when it has educational institution data' do
    subject { CfdiProcessor::StampedExtractor.new(xml_with_educational_institution) }

    describe '#extract_data_from_xml' do
      it { expect(subject.concepts[0]['educational_institutions']).to be_present }
      it { expect(subject.concepts[0]['educational_institutions']['student_name']).to eql('JIMENEZ MUÑOZ ANA LUCIA') }
      it { expect(subject.concepts[0]['educational_institutions']['curp']).to eql('JIMA190614MDFMXNA5') }
      it { expect(subject.concepts[0]['educational_institutions']['educational_level']).to eql('Preescolar') }
    end
  end
end
