require_relative 'Data_Retriever'

class Runner

    parser = Data_Retriever.new
    parser.browse("https://my.fibank.bg/oauth2-server/login?client_id=E_BANK")
    parser.login
    parser.parsing
    parser.gather_credit_info
    parser.gather_debit_info
    parser.gather_last_transactions
    parser.link_transactions_to_accounts
    parser.transform_data_to_hash
    parser.save("/Users/nicolaiandriuta/Andriuta/Parser/result.json")
end