require 'nokogiri'
require 'rubygems'
require 'open-uri'
require 'watir'
require 'pry'
require 'json'
require_relative "Accounts.rb"
require_relative "Transactions.rb"

Selenium::WebDriver::Chrome.driver_path="/usr/local/bin/chromedriver"

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
    @page.css("table[id='dashboardAccounts'] tr[id]").each do |row|
      account_name = row.css("div.info-wrapper span").first.text
      account_available_balance = row.css("td.ng-scope > div.text-center.cellText.ng-scope span").first.text 
      account_currency = row.css("div.text-right.cellText.ng-scope").first.text
      credit_accs = Accounts.new(account_name, account_available_balance, account_currency,"Credit")
      @available_accounts << credit_accs
    end
  end

  def gather_debit_info
    @page.css("#dashStep2 tr[id]").each do |row|
    account_name = row.css("div.info-wrapper span").last.text
    account_currency = @browser.span(:xpath, "(//*[@id='dashboardDeposits']/tbody/tr//span[@bo-bind='row.ccy'])").text
    account_available_balance = row.css("div.text-right.cellText.ng-scope span").first.text
    debit_accs = Accounts.new(account_name , account_currency , account_available_balance ,"Debit" )
    @available_accounts << debit_accs
   end
  end

  def gather_last_transactions
    transactions = page.css("#step1 > td:nth-child(5) > div[class='cellText ng-scope'] > span").first.text 
    @tr_index = 1
    while  @tr_index <= transactions.count do
   transaction_date = page.css('#step1 > td:nth-child(2) > div[style="width: 6.8rem"] > span').(@tr_index).first.text
   transaction_description = page.css('#step1 > td.ng-scope.icon-two-line-col > div > div > p.ng-scope').(@tr_index).first.text + " " + page.css('#step1 > td.ng-scope.icon-two-line-col > div > div    > p:nth-child(2)').first.text
   transaction_amount = page.css("#step1 > td[style='width: 11.2rem;']:nth-child(6) > div > span").(@tr_index).first.text
   transaction_account_name = page.css("#step1 > td:nth-child(5) > div[class='cellText ng-scope'] > span").(@tr_index).first.text
   tr = Transactions.new(transaction_date, transaction_description, transaction_amount, transaction_account_name)
  @transactions_records << tr
  @tr_index += 1
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
          "amount" => transaction.amount
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
