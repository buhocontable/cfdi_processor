# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CfdiProcessor::RetencionesExtractor do
  let(:retenciones_v20_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <retenciones:Retenciones xmlns:retenciones="http://www.sat.gob.mx/esquemas/retencionpago/2"
                               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                               Version="2.0"
                               FolioInt="12345"
                               FechaExp="2024-01-15T10:30:00"
                               CveRetenc="14"
                               LugarExpRetenc="06600">
        <retenciones:Emisor RfcE="ABC123456789" NomDenRazSocE="Empresa Emisora SA" RegimenFiscalE="601"/>
        <retenciones:Receptor Nacionalidad="Nacional">
          <retenciones:Nacional RFCRecep="XYZ987654321" NomDenRazSocR="Receptor Nacional SA" DomicilioFiscalR="03100"/>
        </retenciones:Receptor>
        <retenciones:Periodo MesIni="01" MesFin="12" Ejerc="2024"/>
        <retenciones:Totales MontoTotOperacion="100000.00" MontoTotGrav="80000.00" MontoTotExent="20000.00" MontoTotRet="16000.00">
          <retenciones:ImpRetenidos>
            <retenciones:ImpRetenido BaseRet="80000.00" Impuesto="001" MontoRet="12800.00" TipoPagoRet="Pago definitivo"/>
            <retenciones:ImpRetenido BaseRet="80000.00" Impuesto="002" MontoRet="3200.00" TipoPagoRet="Pago definitivo"/>
          </retenciones:ImpRetenidos>
        </retenciones:Totales>
        <retenciones:Complemento>
          <tfd:TimbreFiscalDigital xmlns:tfd="http://www.sat.gob.mx/TimbreFiscalDigital"
                                   UUID="ABC12345-1234-1234-1234-123456789012"
                                   FechaTimbrado="2024-01-15T10:31:00"
                                   RfcProvCertif="SAT970701NN3"
                                   SelloCFD="abc123..."
                                   SelloSAT="xyz789..."
                                   NoCertificadoSAT="00001000000500000001"/>
        </retenciones:Complemento>
      </retenciones:Retenciones>
    XML
  end

  let(:retenciones_v10_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <retenciones:Retenciones xmlns:retenciones="http://www.sat.gob.mx/esquemas/retencionpago/1"
                               Version="1.0"
                               FolioInt="54321"
                               FechaExp="2020-06-15T14:00:00"
                               CveRetenc="02">
        <retenciones:Emisor RFCEmisor="DEF456789012"/>
        <retenciones:Receptor Nacionalidad="Extranjero">
          <retenciones:Extranjero NumRegIdTrib="US12345" NomDenRazSocR="Foreign Company LLC"/>
        </retenciones:Receptor>
        <retenciones:Periodo MesIni="06" MesFin="06" Ejercicio="2020"/>
        <retenciones:Totales MontoTotOperacion="50000.00" MontoTotGrav="50000.00" MontoTotExent="0" MontoTotRet="5000.00"/>
      </retenciones:Retenciones>
    XML
  end

  let(:retenciones_with_dividendos_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <retenciones:Retenciones xmlns:retenciones="http://www.sat.gob.mx/esquemas/retencionpago/2"
                               xmlns:dividendos="http://www.sat.gob.mx/esquemas/retencionpago/1/dividendos"
                               Version="2.0"
                               CveRetenc="06">
        <retenciones:Emisor RfcE="DIV123456789"/>
        <retenciones:Receptor Nacionalidad="Nacional">
          <retenciones:Nacional RFCRecep="REC987654321" NomDenRazSocR="Receptor SA"/>
        </retenciones:Receptor>
        <retenciones:Periodo MesIni="01" MesFin="12" Ejerc="2024"/>
        <retenciones:Totales MontoTotOperacion="200000.00" MontoTotRet="20000.00"/>
        <retenciones:Complemento>
          <dividendos:Dividendos Version="1.0">
            <dividendos:DividOUtil CveTipDivOUtil="01" MontISRAcredRetMexico="5000.00" TipoSocDistrDiv="Sociedad Nacional" MontDivAcumNal="150000.00"/>
          </dividendos:Dividendos>
        </retenciones:Complemento>
      </retenciones:Retenciones>
    XML
  end

  describe '#extract' do
    context 'with Retenciones 2.0' do
      subject(:extractor) { described_class.new(retenciones_v20_xml) }

      it 'extracts version' do
        result = extractor.extract
        expect(result[:version]).to eq('2.0')
      end

      it 'extracts folio_int' do
        result = extractor.extract
        expect(result[:folio_int]).to eq('12345')
      end

      it 'extracts fecha_exp' do
        result = extractor.extract
        expect(result[:fecha_exp]).to eq('2024-01-15T10:30:00')
      end

      it 'extracts cve_retenc' do
        result = extractor.extract
        expect(result[:cve_retenc]).to eq('14')
      end

      it 'extracts emisor data' do
        result = extractor.extract
        expect(result[:emisor][:rfc_emisor]).to eq('ABC123456789')
        expect(result[:emisor][:nom_den_raz_soc_e]).to eq('Empresa Emisora SA')
        expect(result[:emisor][:regimen_fiscal_e]).to eq('601')
      end

      it 'extracts receptor nacional' do
        result = extractor.extract
        expect(result[:receptor][:nacionalidad]).to eq('Nacional')
        expect(result[:receptor][:rfc_r]).to eq('XYZ987654321')
        expect(result[:receptor][:nom_den_raz_soc_r]).to eq('Receptor Nacional SA')
        expect(result[:receptor][:domicilio_fiscal_r]).to eq('03100')
      end

      it 'extracts periodo' do
        result = extractor.extract
        expect(result[:periodo][:mes_ini]).to eq('01')
        expect(result[:periodo][:mes_fin]).to eq('12')
        expect(result[:periodo][:ejerc]).to eq('2024')
      end

      it 'extracts totales' do
        result = extractor.extract
        expect(result[:totales][:monto_tot_operacion]).to eq('100000.00')
        expect(result[:totales][:monto_tot_grav]).to eq('80000.00')
        expect(result[:totales][:monto_tot_exent]).to eq('20000.00')
        expect(result[:totales][:monto_tot_ret]).to eq('16000.00')
      end

      it 'extracts ISR retenido' do
        result = extractor.extract
        expect(result[:totales][:isr_ret]).to eq('12800.00')
      end

      it 'extracts IVA retenido' do
        result = extractor.extract
        expect(result[:totales][:iva_ret]).to eq('3200.00')
      end

      it 'extracts impuestos retenidos array' do
        result = extractor.extract
        expect(result[:totales][:impuestos_retenidos]).to be_an(Array)
        expect(result[:totales][:impuestos_retenidos].length).to eq(2)

        isr = result[:totales][:impuestos_retenidos].find { |i| i[:impuesto] == '001' }
        expect(isr[:base_ret]).to eq('80000.00')
        expect(isr[:monto_ret]).to eq('12800.00')
      end

      it 'extracts timbre fiscal digital' do
        result = extractor.extract
        expect(result[:complemento][:timbre][:uuid]).to eq('ABC12345-1234-1234-1234-123456789012')
        expect(result[:complemento][:timbre][:fecha_timbrado]).to eq('2024-01-15T10:31:00')
        expect(result[:complemento][:timbre][:rfc_prov_certif]).to eq('SAT970701NN3')
      end
    end

    context 'with Retenciones 1.0' do
      subject(:extractor) { described_class.new(retenciones_v10_xml) }

      it 'extracts version' do
        result = extractor.extract
        expect(result[:version]).to eq('1.0')
      end

      it 'extracts emisor with old attribute names' do
        result = extractor.extract
        expect(result[:emisor][:rfc_emisor]).to eq('DEF456789012')
      end

      it 'extracts receptor extranjero' do
        result = extractor.extract
        expect(result[:receptor][:nacionalidad]).to eq('Extranjero')
        expect(result[:receptor][:num_reg_id_trib]).to eq('US12345')
        expect(result[:receptor][:nom_den_raz_soc_r]).to eq('Foreign Company LLC')
      end

      it 'extracts periodo with Ejercicio attribute' do
        result = extractor.extract
        expect(result[:periodo][:ejerc]).to eq('2020')
      end
    end

    context 'with Dividendos complement' do
      subject(:extractor) { described_class.new(retenciones_with_dividendos_xml) }

      it 'extracts dividendos data' do
        result = extractor.extract
        expect(result[:complemento][:dividendos]).not_to be_nil
        expect(result[:complemento][:dividendos][:version]).to eq('1.0')
      end

      it 'extracts DividOUtil data' do
        result = extractor.extract
        divid = result[:complemento][:dividendos][:divid_o_util]
        expect(divid[:cve_tip_div_o_util]).to eq('01')
        expect(divid[:mont_isr_acred_ret_mexico]).to eq('5000.00')
        expect(divid[:tipo_soc_distr_div]).to eq('Sociedad Nacional')
        expect(divid[:mont_div_acum_nal]).to eq('150000.00')
      end
    end

    context 'with missing nodes' do
      it 'returns empty hash for missing emisor' do
        xml = '<retenciones:Retenciones xmlns:retenciones="http://www.sat.gob.mx/esquemas/retencionpago/2" Version="2.0"></retenciones:Retenciones>'
        result = described_class.new(xml).extract
        expect(result[:emisor]).to eq({})
      end

      it 'returns nil for missing complemento' do
        xml = '<retenciones:Retenciones xmlns:retenciones="http://www.sat.gob.mx/esquemas/retencionpago/2" Version="2.0"><retenciones:Emisor/></retenciones:Retenciones>'
        result = described_class.new(xml).extract
        expect(result[:complemento]).to be_nil
      end
    end

    context 'with non-Retenciones XML' do
      it 'returns empty hash' do
        xml = '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4"><cfdi:Emisor/></cfdi:Comprobante>'
        result = described_class.new(xml).extract
        expect(result).to eq({})
      end
    end
  end

  describe 'initialization' do
    it 'accepts XML string' do
      extractor = described_class.new(retenciones_v20_xml)
      expect(extractor.nokogiri_xml).to be_a(Nokogiri::XML::Document)
    end

    it 'accepts Nokogiri::XML::Document' do
      doc = Nokogiri::XML(retenciones_v20_xml)
      extractor = described_class.new(doc)
      expect(extractor.extract[:version]).to eq('2.0')
    end

    it 'raises error for invalid input' do
      expect { described_class.new(123) }.to raise_error(ArgumentError)
    end
  end
end
