unit providers.constsql.dao;

interface

type
  TSql = class
  const
    SQLQuantidadeproduto = 'select count(*) from tabitens ';
    SQLQuantidadePreco = 'select count(*) from tabprecos2 ';
    SQLProduto = 'select * from tabitens order by ite_cod_interno ';
    SQLPreco = 'select * from tabprecos2 order by tpc_cod_interno ';
    SQlSProduto = 'select * from tabitens ';
    SQLSPReco = 'select * from tabprecos2 ';
    SQLFullJoinProdutoAndPreco =
      'select * from tabitens ite full join tabprecos2 tpc on ite.ite_cod_interno = tpc.tpc_cod_interno order by ite.ite_cod_interno';
  end;

implementation

end.
