###
    Exemplo dos conceitos de grampear e 'xerocar'
    Copyright (c) 2011 Leonardo Eloy
    http://github.com/leonardoeloy
###

db = require './db'
puts = console.log

# Notas Fiscais
nfUm =
    tipo: "saída"
    naturezaOperacao: "Prestação de Serviços"
    cfop: 5933
    nomeRazaoSocial: "Fulano de Tal Co."
    cpfCnpj: "00.000.000/0001-01"
    endereco: "Rua Bem Ali, 100"
    bairroDistrito: "Aldeota"
    municipio: "Fortaleza"
    fone: "85.9999.8888"
    dtEmissao: "10/10/2011"
    itens: [
        {
            descricao: "Conserto de 01 impressora",
            quantidade: 1,
            valor: 500.00
        },
        {
            descricao: "Conserto de 02 notebooks",
            quantidade: 2,
            valor: 1000.00
        }
    ]


nfDois =
    tipo: "entrada"
    naturezaOperacao: "Compra de Materiais"
    cfop: 4000
    nomeRazaoSocial: "Apple Inc."
    cpfCnpj: "00.000.000/0002-02"
    endereco: "One Apple Fag Way"
    bairroDistrito: "Zapple"
    municipio: "Cupertino"
    fone: "85.6666.7777"
    dtEmissao: "07/07/2011"
    itens: [
        {
            descricao: "iPad",
            quantidade: 10,
            valor: 1700.00
        },
        {
            descricao: "iPad Cover",
            quantidade: 10,
            valor: 160.00
        }
    ]

exports.nfs = new db.Database 'notaFiscal', [nfUm, nfDois]

# Lançamentos Contábeis

lcUm =
    dtDocumento: "10/10/2011"
    contaDevedora: "10.1.1.1"
    contaCredora: "9.8.8.8"
    valorLancamento: 2500.00
    historico: "Serviço Consumidor Final"

lcDois =
    dtdocumento: "07/07/2011"
    contaDevedora: "9.8.8.8"
    contaCredora: "10.1.1.1"
    valorLancamento: 18600.00
    historico: "Compra Dinheiro Fornecedor"

exports.lcs = new db.Database 'lancamentoContabil', [lcUm, lcDois]



