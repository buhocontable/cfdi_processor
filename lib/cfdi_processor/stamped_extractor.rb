module CfdiProcessor
  class StampedExtractor < CfdiProcessor::DataExtractorBase
    attr_accessor :receipt, :issuer, :receiver, :concepts, :taxes

    def extract_data_from_xml
      receipt_data_from_xml
      issuer_data_from_xml
      receiver_data_from_xml
      concepts_data_from_xml
      taxes_data_from_xml

      self
    end

    def translate_data
      _translate_receipt(:cfdi)
      _translate_issuer(:cfdi)
      _translate_receiver(:cfdi)
      _translate_concepts(:cfdi)
      _translate_taxes(:cfdi)

      self
    end

    private

    def receipt_data_from_xml
      @receipt = nokogiri_xml.at('Comprobante').to_h
    end

    def issuer_data_from_xml
      @issuer = nokogiri_xml.at('Emisor').to_h
    end

    def receiver_data_from_xml
      @receiver = nokogiri_xml.at('Receptor').to_h
    end

    def concepts_data_from_xml
      @concepts = nokogiri_xml.at('Conceptos').element_children.map do |e|
        concepts = e.to_h
        concepts["Traslados"]   = (e.at('Impuestos').css("Traslado").map{|e| e.to_h})
        concepts["Retenciones"] = (e.at('Impuestos').css("Retencion").map{|e| e.to_h})
        concepts
      end
    end

    def taxes_data_from_xml
      @taxes = nokogiri_xml.css('Comprobante Impuestos').last.element_children.map do |e|
        taxes = nokogiri_xml.css('Comprobante Impuestos').last.to_h
        taxes["Traslados"]   = (e.css("Traslado").map{|e| e.to_h})
        taxes["Retenciones"] = (e.css("Retencion").map{|e| e.to_h})
        taxes
      end
    end
  end
end