# frozen_string_literal: true

module CfdiProcessor
  class StampedExtractor < CfdiProcessor::DataExtractorBase
    attr_accessor :receipt, :issuer, :receiver, :concepts, :taxes, :complement, :payments, :payroll, :local_taxes,
                  :global_info, :carta_porte, :combustibles

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
      global_info_from_xml
      carta_porte_data_from_xml
      combustibles_data_from_xml

      self
    end

    private

    def receipt_data_from_xml
      @receipt = nokogiri_xml.at('Comprobante').to_h
      @base_hash['receipt'] = @receipt
    end

    def issuer_data_from_xml
      @issuer = nokogiri_xml.at('Emisor').to_h
      @base_hash['issuer'] = @issuer
    end

    def receiver_data_from_xml
      @receiver = nokogiri_xml.at('Receptor').to_h
      @base_hash['receiver'] = @receiver
    end

    def global_info_from_xml
      @global_info = nokogiri_xml.at('InformacionGlobal').to_h
      @base_hash['global_info'] = @global_info
    end

    def concepts_data_from_xml
      @concepts = nokogiri_xml.at('Conceptos').element_children.map do |e|
        concepts = e.to_h
        concepts['Traslados']   = e.at('Impuestos').css('Traslado').map(&:to_h) if e.at('Impuestos')
        concepts['Retenciones'] = e.at('Impuestos').css('Retencion').map(&:to_h) if e.at('Impuestos')
        concepts['IntitucionesEducativas'] = e.at('instEducativas').to_h if e.at('instEducativas')
        concepts
      end
      @base_hash['concepts'] = @concepts
    end

    def taxes_data_from_xml
      return [] if nokogiri_xml.css('Comprobante Impuestos').blank?

      base_node = nokogiri_xml.css('Comprobante Impuestos').last
      taxes = base_node&.to_h || {}
      taxes['Traslados']   = base_node.css('Traslado').map(&:to_h)
      taxes['Retenciones'] = base_node.css('Retencion').map(&:to_h)
      @taxes = taxes
      @base_hash['taxes'] = @taxes
    end

    def complement_data_from_xml
      @complement = nokogiri_xml.at('TimbreFiscalDigital').to_h
      @base_hash['complement'] = @complement
    end

    def payment_data_from_xml
      return [] if nokogiri_xml.css('Pago').blank?

      @payments = @nokogiri_xml.at('Pagos').css('Pago').map do |e|
        payments = e.to_h
        payments['DoctoRelacionado'] = e.css('DoctoRelacionado').map do |doc|
          doc_hash = doc.to_h
          if doc_hash['ObjetoImpDR'] == '02'
            transferred_taxes = doc.css('TrasladoDR')
            retained_taxes = doc.css('RetencionDR')
            doc_hash['ImpuestosDR'] = {}
            doc_hash['ImpuestosDR']['TrasladosDR'] = transferred_taxes.map(&:to_h)
            doc_hash['ImpuestosDR']['RetencionesDR'] = retained_taxes.map(&:to_h)
          end
          doc_hash
        end
        payments
      end
      @base_hash['payments'] = @payments
    end

    def payroll_data_from_xml
      payroll = nokogiri_xml.at('Comprobante Nomina')
      if payroll
        payroll_attribute = payroll.to_h
        payroll_attribute['Emisor']       = payroll.at('Emisor').to_h
        payroll_attribute['Receptor']     = payroll.at('Receptor').to_h
        payroll_perceptions = payroll.at('Percepciones')
        payroll_attribute['Percepciones'] = payroll_perceptions.to_h
        if payroll_perceptions
          payroll_attribute['Percepciones']['items'] = payroll_perceptions.css('Percepcion').map(&:to_h)
        end
        payroll_deductions = payroll.at('Deducciones')
        payroll_attribute['Deducciones'] = payroll_deductions.to_h
        if payroll_deductions
          payroll_attribute['Deducciones']['items'] = payroll_deductions.css('Deduccion').map(&:to_h)
        end
        payroll_other_payments = payroll.at('OtrosPagos')
        payroll_attribute['OtrosPagos'] = {}
        if payroll_other_payments
          payroll_attribute['OtrosPagos']['items'] = payroll_other_payments.css('OtroPago').map(&:to_h)
        end
        @payroll = payroll_attribute
        @base_hash['payroll'] = @payroll
      end
    end

    def local_taxes_data_from_xml
      if nokogiri_xml.at('ImpuestosLocales')
        @local_taxes = nokogiri_xml.at('ImpuestosLocales').to_h
        @base_hash['local_taxes'] = @local_taxes
      end
    end

    # Carta Porte complement extraction (versions 2.0, 3.0, 3.1)
    def carta_porte_data_from_xml
      cp_node = nokogiri_xml.at('CartaPorte') ||
                nokogiri_xml.at('CartaPorte20') ||
                nokogiri_xml.at('CartaPorte30') ||
                nokogiri_xml.at('CartaPorte31')
      return unless cp_node

      carta_porte_attrs = cp_node.to_h

      # Ubicaciones (origin/destination)
      carta_porte_attrs['Ubicaciones'] = cp_node.css('Ubicacion').map do |u|
        ubicacion = u.to_h
        ubicacion['Domicilio'] = u.at('Domicilio')&.to_h
        ubicacion
      end

      # Mercancias (merchandise)
      mercancias_node = cp_node.at('Mercancias')
      if mercancias_node
        carta_porte_attrs['Mercancias'] = mercancias_node.to_h
        carta_porte_attrs['Mercancias']['items'] = mercancias_node.css('Mercancia').map(&:to_h)
      end

      # Autotransporte (truck transport)
      auto_node = cp_node.at('Autotransporte')
      if auto_node
        carta_porte_attrs['Autotransporte'] = auto_node.to_h
        carta_porte_attrs['Autotransporte']['IdentificacionVehicular'] = auto_node.at('IdentificacionVehicular')&.to_h
        carta_porte_attrs['Autotransporte']['Seguros'] = auto_node.at('Seguros')&.to_h
        carta_porte_attrs['Autotransporte']['Remolques'] = auto_node.css('Remolque').map(&:to_h)
      end

      # TransporteMaritimo
      maritimo_node = cp_node.at('TransporteMaritimo')
      carta_porte_attrs['TransporteMaritimo'] = maritimo_node.to_h if maritimo_node

      # TransporteAereo
      aereo_node = cp_node.at('TransporteAereo')
      carta_porte_attrs['TransporteAereo'] = aereo_node.to_h if aereo_node

      # TransporteFerroviario
      ferro_node = cp_node.at('TransporteFerroviario')
      if ferro_node
        carta_porte_attrs['TransporteFerroviario'] = ferro_node.to_h
        carta_porte_attrs['TransporteFerroviario']['DerechosDePaso'] = ferro_node.css('DerechosDePaso').map(&:to_h)
        carta_porte_attrs['TransporteFerroviario']['Carros'] = ferro_node.css('Carro').map(&:to_h)
      end

      # FiguraTransporte (operators, owners)
      figura_node = cp_node.at('FiguraTransporte')
      if figura_node
        carta_porte_attrs['FiguraTransporte'] = figura_node.css('TiposFigura').map(&:to_h)
      end

      @carta_porte = carta_porte_attrs
      @base_hash['carta_porte'] = @carta_porte
    end

    # Combustibles complement extraction (Estado de Cuenta de Combustibles versions 1.1, 1.2)
    def combustibles_data_from_xml
      ecc_node = nokogiri_xml.at('EstadoDeCuentaCombustible') ||
                 nokogiri_xml.at('ecc12:EstadoDeCuentaCombustible') ||
                 nokogiri_xml.at('ecc11:EstadoDeCuentaCombustible')
      return unless ecc_node

      combustibles_attrs = ecc_node.to_h

      # Conceptos
      conceptos_node = ecc_node.at('Conceptos') || ecc_node
      concepto_items = conceptos_node.css('ConceptoEstadoDeCuentaCombustible')
      concepto_items = conceptos_node.css('Concepto') if concepto_items.empty?

      combustibles_attrs['Conceptos'] = concepto_items.map do |c|
        concepto = c.to_h
        # Traslados within each concept
        traslados_node = c.at('Traslados')
        concepto['Traslados'] = traslados_node.css('Traslado').map(&:to_h) if traslados_node
        # Determinados (v1.2)
        determinados_node = c.at('Determinados')
        concepto['Determinados'] = determinados_node.css('Determinado').map(&:to_h) if determinados_node
        concepto
      end

      @combustibles = combustibles_attrs
      @base_hash['combustibles'] = @combustibles
    end
  end
end
