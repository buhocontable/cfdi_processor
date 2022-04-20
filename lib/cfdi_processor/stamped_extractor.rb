module CfdiProcessor
  class StampedExtractor < CfdiProcessor::DataExtractorBase
    attr_accessor :receipt, :issuer, :receiver, :concepts, :taxes, :complement, :payments, :payroll, :local_taxes

    def extract_data_from_xml
      receipt_data_from_xml
      issuer_data_from_xml
      receiver_data_from_xml
      concepts_data_from_xml
      taxes_data_from_xml
      complement_data_from_xml
      payment_data_from_xml
      payroll_data_from_xml
      local_taxes_data_from_xml

      self
    end

    def translate_data
      _translate_receipt(:cfdi)
      _translate_issuer(:cfdi)
      _translate_receiver(:cfdi)
      _translate_concepts(:cfdi)
      _translate_taxes(:cfdi)
      _translate_complement(:cfdi)
      _translate_payments(:cfdi)
      _translate_local_taxes(:cfdi)
      _translate_payroll_data_from_xml(:cfdi)

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
        concepts["Traslados"]   = (e.at('Impuestos').css("Traslado").map{|e| e.to_h}) if e.at('Impuestos')
        concepts["Retenciones"] = (e.at('Impuestos').css("Retencion").map{|e| e.to_h}) if e.at('Impuestos')
        concepts
      end
    end

    def taxes_data_from_xml
      return [] if nokogiri_xml.css('Comprobante Impuestos').blank?
      base_node = nokogiri_xml.css('Comprobante Impuestos').last
      taxes = {} 
      taxes["Traslados"]   = (base_node.css("Traslado").map{|e| e.to_h})
      taxes["Retenciones"] = (base_node.css("Retencion").map{|e| e.to_h})
      @taxes = taxes   
    end

    def complement_data_from_xml
      @complement = nokogiri_xml.at('TimbreFiscalDigital').to_h
    end

    def payment_data_from_xml 
      return [] if nokogiri_xml.css('Pago').blank?
      @payments = @nokogiri_xml.at('Pagos').element_children.map do |e|
        payments = e.to_h
        payments["DoctoRelacionado"] = e.css('DoctoRelacionado').map do |doc|
          doc_hash = doc.to_h
          if doc_hash["ObjetoImpDR"] == "02"
            transferred_taxes = doc.css('TrasladoDR')
            doc_hash["ImpuestosDR"] = {}
            doc_hash["ImpuestosDR"]["TrasladosDR"] = transferred_taxes.map do |transferred|
              transferred.to_h
            end
          end
          doc_hash
        end
        payments
      end
    end

    def payroll_data_from_xml
      payroll = nokogiri_xml.at('Comprobante Nomina')
      if payroll
        payroll_attribute = payroll.to_h
        payroll_attribute["Emisor"]       = payroll.at("Emisor").to_h
        payroll_attribute["Receptor"]     = payroll.at("Receptor").to_h
        payroll_perceptions = payroll.at('Percepciones')
        payroll_attribute['Percepciones'] = payroll_perceptions.to_h
        if payroll_perceptions
          payroll_attribute['Percepciones']["items"] = (payroll_perceptions.css("Percepcion").map{|e| e.to_h})
        end
        payroll_deductions = payroll.at('Deducciones')
        payroll_attribute["Deducciones"] = payroll_deductions.to_h
        if payroll_deductions
          payroll_attribute["Deducciones"]["items"] = (payroll_deductions.css("Deduccion").map{|e| e.to_h})
        end
        payroll_other_payments = payroll.at('OtrosPagos')
        payroll_attribute["OtrosPagos"] = {} 
        if payroll_other_payments
          payroll_attribute["OtrosPagos"]["items"] = (payroll_other_payments.css("OtroPago").map{|e| e.to_h})
        end
        @payroll = payroll_attribute
      end
    end

    def local_taxes_data_from_xml 
      @local_taxes = nokogiri_xml.at('ImpuestosLocales').to_h
    end
  end
end