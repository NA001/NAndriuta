require 'nokogiri'
require 'rubygems'
require 'open-uri'
require 'watir'
require 'pry'
require 'json'
require_relative "Account.rb"
require_relative "Transaction.rb"


class Data_Retriever
  def initialize()
    @available_accounts = []
    @transactions_records = []
    @browser = Watir::Browser.new :chrome
  end

  def browse(url)
    @browser.goto(url)
    @browser.div(:id => "oCAPICOM").wait_while_present(&:present?)
  end

  def login
    @browser.a(class: 'ng-binding').wait_until(&:present?).click
    @browser.a(id: 'demo-link').click
    @browser.element(:id => "step1").wait_until(&:present?)
  end

  def parsing
    @page = Nokogiri.HTML(@browser.html)
    puts "Parsing is done."
  end

  def gather_credit_info
    @page.css("#dashboardAccounts tr[id]").each do |row|
    account_name = row.css("span[bo-bind='row.iban']").text
    account_currency = row.css("span[bo-bind='row.acyAvlBal | sgCurrency']").text.to_f 
    account_available_balance = row.css("span[bo-bind='row.ccy']").text
    credit_accs = Account.new(account_name , account_available_balance , account_currency , "Credit")
    @available_accounts << credit_accs
    end
  end

  def gather_debit_info
    @page.css("#dashStep2 tr[id]").each do |row|
    account_name = row.css("span[bo-bind='row.iban']").text
    account_currency = row.css("span[bo-bind='row.ccy']").text
    account_available_balance = row.css("span[bo-bind='row.acyAvlBal | sgCurrency']").text.to_f
    debit_accs = Account.new(account_name , account_currency , account_available_balance ,"Debit" )
    @available_accounts << debit_accs
   end
  end

  def gather_last_transactions
	@page.css("#lastFiveTransactions tr[id='step1']").each do |transaction|
	transaction_date = transaction.css("td:nth-child(2)").text
    transaction_description_first_row = transaction.css("td.ng-scope.icon-two-line-col p:nth-child(1)").text
    transaction_description_second_row = transaction.css("td.ng-scope.icon-two-line-col p:nth-child(2)").text
    transaction_amount = transaction.css("td:nth-child(6)").text.to_f
    transaction_currency = transaction.css("td:nth-child(6)").text.chars.last(3).join
    transaction_account_name = transaction.css("td:nth-child(5)").text
    transaction_data = Transaction.new(transaction_date , transaction_description_first_row + " " + transaction_description_second_row, transaction_amount , transaction_account_name, transaction_currency)
    @transactions_records << transaction_data
   end
  end



  def link_transactions_to_accounts
    @available_accounts.each do |available_accounts|
      @transactions_records.each do |transaction|
        if(transaction.account_name == available_accounts.name)
          available_accounts.transactions << transaction
      end
    end
  end
    
  def transform_data_to_hash
    @json_hash = {"Accounts" => []}
    @available_accounts.each do |account|
    account_hash = {
    "name" => account.name,
    "balance" => account.balance,
    "currency" => account.currency,
    "description" => account.nature,
    "transactions" => []
    }
        
    account.transactions.each do |transaction|
    transaction_hash = {
    "date" => transaction.date,
    "description" => transaction.description,
    "amount" => transaction.amount,
    "currency" => transaction.currency
    }

    account_hash["transactions"] << transaction_hash
    end
    @json_hash["Accounts"] << account_hash
    end
  end


  def save(path)
    File.open(path, "w") do |file|
    file.write(JSON.pretty_generate(@json_hash))
    end
   end
  end
end