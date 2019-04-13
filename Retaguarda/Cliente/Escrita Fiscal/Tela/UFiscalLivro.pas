{ *******************************************************************************
Title: T2Ti ERP
Description: Janela de Cadastro de Livros Fiscais para o m�dulo Escrita Fiscal

The MIT License

Copyright: Copyright (C) 2016 T2Ti.COM

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

The author may be contacted at:
t2ti.com@gmail.com</p>

@author Albert Eije (T2Ti.COM)
@version 2.0
******************************************************************************* }
unit UFiscalLivro;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UTelaCadastro, DB, DBClient, Menus, StdCtrls, ExtCtrls, Buttons, Grids,
  DBGrids, JvExDBGrids, JvDBGrid, JvDBUltimGrid, ComCtrls, FiscalLivroVO,
  FiscalLivroController, Tipos, Atributos, Constantes, LabeledCtrls, JvToolEdit,
  Mask, JvExMask, JvBaseEdits, Math, StrUtils, ActnList, Generics.Collections,
  RibbonSilverStyleActnCtrls, ActnMan, ToolWin, ActnCtrls, Controller;

type
  [TFormDescription(TConstantes.MODULO_ESCRITA_FISCAL, 'Livros Fiscais')]

  TFFiscalLivro = class(TFTelaCadastro)
    DSFiscalTermo: TDataSource;
    CDSFiscalTermo: TClientDataSet;
    PanelMestre: TPanel;
    PageControlItens: TPageControl;
    tsItens: TTabSheet;
    PanelItens: TPanel;
    GridDetalhe: TJvDBUltimGrid;
    EditDescricao: TLabeledEdit;
    CDSFiscalTermoID: TIntegerField;
    CDSFiscalTermoID_FISCAL_LIVRO: TIntegerField;
    CDSFiscalTermoABERTURA_ENCERRAMENTO: TStringField;
    CDSFiscalTermoNUMERO: TIntegerField;
    CDSFiscalTermoPAGINA_INICIAL: TIntegerField;
    CDSFiscalTermoPAGINA_FINAL: TIntegerField;
    CDSFiscalTermoREGISTRADO: TStringField;
    CDSFiscalTermoNUMERO_REGISTRO: TStringField;
    CDSFiscalTermoDATA_DESPACHO: TDateField;
    CDSFiscalTermoDATA_ABERTURA: TDateField;
    CDSFiscalTermoDATA_ENCERRAMENTO: TDateField;
    CDSFiscalTermoESCRITURACAO_INICIO: TDateField;
    CDSFiscalTermoESCRITURACAO_FIM: TDateField;
    CDSFiscalTermoTEXTO: TStringField;
    procedure FormCreate(Sender: TObject);
    procedure GridDblClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
    procedure GridParaEdits; override;
    procedure LimparCampos; override;
    procedure ControlaBotoes; override;

    // Controles CRUD
    function DoInserir: Boolean; override;
    function DoEditar: Boolean; override;
    function DoExcluir: Boolean; override;
    function DoSalvar: Boolean; override;

    procedure ConfigurarLayoutTela;
  end;

var
  FFiscalLivro: TFFiscalLivro;

implementation

uses ULookup, Biblioteca, UDataModule, FiscalTermoVO;
{$R *.dfm}

{$REGION 'Controles Infra'}
procedure TFFiscalLivro.FormCreate(Sender: TObject);
begin
  ClasseObjetoGridVO := TFiscalLivroVO;
  ObjetoController := TFiscalLivroController.Create;

  inherited;
end;

procedure TFFiscalLivro.LimparCampos;
begin
  inherited;
  CDSFiscalTermo.EmptyDataSet;
end;

procedure TFFiscalLivro.ConfigurarLayoutTela;
begin
  PanelEdits.Enabled := True;

  if StatusTela = stNavegandoEdits then
  begin
    PanelMestre.Enabled := False;
    PanelItens.Enabled := False;
  end
  else
  begin
    PanelMestre.Enabled := True;
    PanelItens.Enabled := True;
  end;
end;

procedure TFFiscalLivro.ControlaBotoes;
begin
  inherited;

  BotaoImprimir.Visible := False;
end;
{$ENDREGION}

{$REGION 'Controles CRUD'}
function TFFiscalLivro.DoInserir: Boolean;
begin
  Result := inherited DoInserir;

  ConfigurarLayoutTela;
  if Result then
  begin
    EditDescricao.SetFocus;
  end;
end;

function TFFiscalLivro.DoEditar: Boolean;
begin
  Result := inherited DoEditar;

  ConfigurarLayoutTela;
  if Result then
  begin
    EditDescricao.SetFocus;
  end;
end;

function TFFiscalLivro.DoExcluir: Boolean;
begin
  if inherited DoExcluir then
  begin
    try
      TController.ExecutarMetodo('FiscalLivroController.TFiscalLivroController', 'Exclui', [IdRegistroSelecionado], 'DELETE', 'Boolean');
      Result := TController.RetornoBoolean;
    except
      Result := False;
    end;
  end
  else
  begin
    Result := False;
  end;

  if Result then
    TController.ExecutarMetodo('FiscalLivroController.TFiscalLivroController', 'Consulta', [Trim(Filtro), Pagina.ToString, False], 'GET', 'Lista');
end;

function TFFiscalLivro.DoSalvar: Boolean;
var
  FiscalTermo: TFiscalTermoVO;
begin
  Result := inherited DoSalvar;

  if Result then
  begin
    try
      if not Assigned(ObjetoVO) then
        ObjetoVO := TFiscalLivroVO.Create;

      TFiscalLivroVO(ObjetoVO).IdEmpresa := Sessao.Empresa.Id;
      TFiscalLivroVO(ObjetoVO).Descricao := EditDescricao.Text;

      // Termos
      TFiscalLivroVO(ObjetoVO).ListaFiscalTermoVO := TObjectList<TFiscalTermoVO>.Create;
      CDSFiscalTermo.DisableControls;
      CDSFiscalTermo.First;
      while not CDSFiscalTermo.Eof do
      begin
        FiscalTermo := TFiscalTermoVO.Create;
        FiscalTermo.Id := CDSFiscalTermoID.AsInteger;
        FiscalTermo.IdFiscalLivro := TFiscalLivroVO(ObjetoVO).Id;
        FiscalTermo.AberturaEncerramento := CDSFiscalTermoABERTURA_ENCERRAMENTO.AsString;
        FiscalTermo.Numero := CDSFiscalTermoNUMERO.AsInteger;
        FiscalTermo.PaginaInicial := CDSFiscalTermoPAGINA_INICIAL.AsInteger;
        FiscalTermo.PaginaFinal := CDSFiscalTermoPAGINA_FINAL.AsInteger;
        FiscalTermo.Registrado := CDSFiscalTermoREGISTRADO.AsString;
        FiscalTermo.NumeroRegistro := CDSFiscalTermoNUMERO_REGISTRO.AsString;
        FiscalTermo.DataDespacho := CDSFiscalTermoDATA_DESPACHO.AsDateTime;
        FiscalTermo.DataAbertura := CDSFiscalTermoDATA_ABERTURA.AsDateTime;
        FiscalTermo.DataEncerramento := CDSFiscalTermoDATA_ENCERRAMENTO.AsDateTime;
        FiscalTermo.EscrituracaoInicio := CDSFiscalTermoESCRITURACAO_INICIO.AsDateTime;
        FiscalTermo.EscrituracaoFim := CDSFiscalTermoESCRITURACAO_FIM.AsDateTime;
        FiscalTermo.Texto := CDSFiscalTermoTEXTO.AsString;
        TFiscalLivroVO(ObjetoVO).ListaFiscalTermoVO.Add(FiscalTermo);
        CDSFiscalTermo.Next;
      end;
      CDSFiscalTermo.EnableControls;

      if StatusTela = stInserindo then
      begin
        TController.ExecutarMetodo('FiscalLivroController.TFiscalLivroController', 'Insere', [TFiscalLivroVO(ObjetoVO)], 'PUT', 'Lista');
      end
      else if StatusTela = stEditando then
      begin
        if TFiscalLivroVO(ObjetoVO).ToJSONString <> StringObjetoOld then
        begin
          TController.ExecutarMetodo('FiscalLivroController.TFiscalLivroController', 'Altera', [TFiscalLivroVO(ObjetoVO)], 'POST', 'Boolean');
        end
        else
          Application.MessageBox('Nenhum dado foi alterado.', 'Mensagem do Sistema', MB_OK + MB_ICONINFORMATION);
      end;
    except
      Result := False;
    end;
  end;
end;
{$ENDREGION}

{$REGION 'Controle de Grid'}
procedure TFFiscalLivro.GridDblClick(Sender: TObject);
begin
  inherited;
  ConfigurarLayoutTela;
end;

procedure TFFiscalLivro.GridParaEdits;
begin
  inherited;

  if not CDSGrid.IsEmpty then
  begin
    ObjetoVO := TFiscalLivroVO(TController.BuscarObjeto('FiscalLivroController.TFiscalLivroController', 'ConsultaObjeto', ['ID=' + IdRegistroSelecionado.ToString], 'GET'));
  end;

  if Assigned(ObjetoVO) then
  begin
    EditDescricao.Text := TFiscalLivroVO(ObjetoVO).Descricao;

    // Preenche as grids internas com os dados das Listas que vieram no objeto
    TController.TratarRetorno<TFiscalTermoVO>(TFiscalLivroVO(ObjetoVO).ListaFiscalTermoVO, True, True, CDSFiscalTermo);

    // Limpa as listas para comparar posteriormente se houve inclus�es/altera��es e subir apenas o necess�rio para o servidor
    TFiscalLivroVO(ObjetoVO).ListaFiscalTermoVO.Clear;

    // Serializa o objeto para consultar posteriormente se houve altera��es
    FormatSettings.DecimalSeparator := '.';
    StringObjetoOld := ObjetoVO.ToJSONString;
    FormatSettings.DecimalSeparator := ',';
  end;

  ConfigurarLayoutTela;
end;
{$ENDREGION}

end.