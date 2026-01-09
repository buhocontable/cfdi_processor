# frozen_string_literal: true

module CfdiProcessor
  # Extracts data from Retenciones e Información de Pagos documents.
  # This is a separate document type from CFDI, not a complement.
  # Handles versions 1.0 and 2.0.
  class RetencionesExtractor
    attr_reader :nokogiri_xml, :retenciones_data

    def initialize(input)
      if input.is_a?(String)
        @nokogiri_xml = Nokogiri::XML(input)
      elsif input.is_a?(Nokogiri::XML::Document)
        @nokogiri_xml = input.dup
      else
        raise ArgumentError, 'Input must be XML string or Nokogiri::XML::Document'
      end

      @nokogiri_xml.remove_namespaces!
    end

    def extract
      return {} unless retenciones_node

      @retenciones_data = {
        version: safe_attr(retenciones_node, 'Version'),
        folio_int: safe_attr(retenciones_node, 'FolioInt'),
        sello: safe_attr(retenciones_node, 'Sello'),
        num_cert: safe_attr(retenciones_node, 'NumCert'),
        certificado: safe_attr(retenciones_node, 'Certificado'),
        fecha_exp: safe_attr(retenciones_node, 'FechaExp'),
        cve_retenc: safe_attr(retenciones_node, 'CveRetenc'),
        desc_retenc: safe_attr(retenciones_node, 'DescRetenc'),
        lugar_exp_retenc: safe_attr(retenciones_node, 'LugarExpRetenc'),

        emisor: extract_emisor,
        receptor: extract_receptor,
        periodo: extract_periodo,
        totales: extract_totales,
        complemento: extract_complemento
      }
    end

    private

    def retenciones_node
      @retenciones_node ||= nokogiri_xml.at('Retenciones')
    end

    def safe_attr(node, attribute)
      node&.[](attribute)
    end

    def extract_emisor
      emisor = retenciones_node.at('Emisor')
      return {} unless emisor

      {
        rfc_emisor: safe_attr(emisor, 'RfcE') || safe_attr(emisor, 'RFCEmisor'),
        nom_den_raz_soc_e: safe_attr(emisor, 'NomDenRazSocE'),
        regimen_fiscal_e: safe_attr(emisor, 'RegimenFiscalE'),
        curp_e: safe_attr(emisor, 'CURPE')
      }
    end

    def extract_receptor
      receptor = retenciones_node.at('Receptor')
      return {} unless receptor

      nacional = receptor.at('Nacional')
      extranjero = receptor.at('Extranjero')

      base = { nacionalidad: safe_attr(receptor, 'Nacionalidad') }

      if nacional
        base.merge(
          rfc_r: safe_attr(nacional, 'RFCRecep') || safe_attr(nacional, 'RfcR'),
          nom_den_raz_soc_r: safe_attr(nacional, 'NomDenRazSocR'),
          curp_r: safe_attr(nacional, 'CURPR'),
          domicilio_fiscal_r: safe_attr(nacional, 'DomicilioFiscalR')
        )
      elsif extranjero
        base.merge(
          num_reg_id_trib: safe_attr(extranjero, 'NumRegIdTrib'),
          nom_den_raz_soc_r: safe_attr(extranjero, 'NomDenRazSocR')
        )
      else
        base
      end
    end

    def extract_periodo
      periodo = retenciones_node.at('Periodo')
      return {} unless periodo

      {
        mes_ini: safe_attr(periodo, 'MesIni'),
        mes_fin: safe_attr(periodo, 'MesFin'),
        ejerc: safe_attr(periodo, 'Ejerc') || safe_attr(periodo, 'Ejercicio')
      }
    end

    def extract_totales
      totales = retenciones_node.at('Totales')
      return {} unless totales

      {
        monto_tot_operacion: safe_attr(totales, 'MontoTotOperacion'),
        monto_tot_grav: safe_attr(totales, 'MontoTotGrav'),
        monto_tot_exent: safe_attr(totales, 'MontoTotExent'),
        monto_tot_ret: safe_attr(totales, 'MontoTotRet'),
        iva_ret: extract_impuesto_retenido(totales, '002'),
        isr_ret: extract_impuesto_retenido(totales, '001'),
        impuestos_retenidos: extract_impuestos_retenidos(totales)
      }
    end

    def extract_impuesto_retenido(totales, impuesto_code)
      imp_retenidos = totales.css('ImpRetenidos')
      return nil if imp_retenidos.empty?

      retencion = imp_retenidos.first.css('ImpRetenido').find do |ir|
        safe_attr(ir, 'Impuesto') == impuesto_code
      end

      return nil unless retencion

      safe_attr(retencion, 'montoRet') || safe_attr(retencion, 'MontoRet')
    end

    def extract_impuestos_retenidos(totales)
      imp_retenidos = totales.css('ImpRetenidos')
      return [] if imp_retenidos.empty?

      imp_retenidos.first.css('ImpRetenido').map do |ir|
        {
          base_ret: safe_attr(ir, 'BaseRet'),
          impuesto: safe_attr(ir, 'Impuesto'),
          monto_ret: safe_attr(ir, 'montoRet') || safe_attr(ir, 'MontoRet'),
          tipo_pago_ret: safe_attr(ir, 'TipoPagoRet')
        }
      end
    end

    def extract_complemento
      complemento = retenciones_node.at('Complemento')
      return nil unless complemento

      result = {}

      # TimbreFiscalDigital
      timbre = complemento.at('TimbreFiscalDigital')
      if timbre
        result[:timbre] = {
          uuid: safe_attr(timbre, 'UUID'),
          fecha_timbrado: safe_attr(timbre, 'FechaTimbrado'),
          rfc_prov_certif: safe_attr(timbre, 'RfcProvCertif'),
          sello_cfd: safe_attr(timbre, 'SelloCFD'),
          sello_sat: safe_attr(timbre, 'SelloSAT'),
          no_certificado_sat: safe_attr(timbre, 'NoCertificadoSAT')
        }
      end

      # Dividendos
      dividendos = complemento.at('Dividendos')
      result[:dividendos] = extract_dividendos(dividendos) if dividendos

      # Intereses
      intereses = complemento.at('Intereses')
      result[:intereses] = extract_intereses(intereses) if intereses

      result.empty? ? nil : result
    end

    def extract_dividendos(dividendos)
      return nil unless dividendos

      divid_o_util = dividendos.at('DividOUtil')

      {
        version: safe_attr(dividendos, 'Version'),
        divid_o_util: divid_o_util ? {
          cve_tip_div_o_util: safe_attr(divid_o_util, 'CveTipDivOUtil'),
          mont_isr_acred_ret_mexico: safe_attr(divid_o_util, 'MontISRAcredRetMexico'),
          mont_isr_acred_ret_extranjero: safe_attr(divid_o_util, 'MontISRAcredRetExtranjero'),
          tipo_soc_distr_div: safe_attr(divid_o_util, 'TipoSocDistrDiv'),
          mont_div_acum_nal: safe_attr(divid_o_util, 'MontDivAcumNal'),
          mont_isr_acred_nal: safe_attr(divid_o_util, 'MontISRAcredNal')
        } : nil
      }
    end

    def extract_intereses(intereses)
      return nil unless intereses

      {
        version: safe_attr(intereses, 'Version'),
        sistema_financiero: safe_attr(intereses, 'SistFinanc'),
        retiro_aors_int_real: safe_attr(intereses, 'RetiroAORSIntReal'),
        oper_financ_deriv: safe_attr(intereses, 'OperFinancDeriv'),
        mont_int_nom_dev: safe_attr(intereses, 'MontIntNomDev'),
        mont_int_nom_acum: safe_attr(intereses, 'MontIntNomAcum'),
        mont_int_real: safe_attr(intereses, 'MontIntReal'),
        perdida: safe_attr(intereses, 'Perdida')
      }
    end
  end
end
