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
  #attr_reader :available_accounts, :transactions_records
  @available_accounts = []
  @transactions_records = []
  @browser = Watir::Browser.new :chrome
  end
  #Opens the browser

  def browse(url)
    @browser.goto(url)
    while @browser.div(:id => "oCAPICOM").exists? do sleep 1 end
  end

  #Does the authentification

  def login
    @browser.a(class: 'ng-binding').click
    @browser.a(id: 'demo-link').click
    @browser.element(:id => "step1").wait_until(&:present?)
  end

  #Parses

  def parsing
    #@page = Nokogiri::HTML.parse(@browser.html)
    @page = Nokogiri.HTML(@browser.html)
    puts "Parsing is done."
  end

  #Gathers credit card information

  def gather_credit_info
    credit_accounts = @page.css("table[id='dashboardAccounts'] tr[id]")
    @ca_index = 1
    while @ca_index <= credit_accounts.count do
      #account_name = @page.css("#dashboardAccounts td.ng-scope.icon-two-line-col > div > div > a > span").text
      account_name = @page.search("#dashStep1 tr:nth-of-type(#{@ca_index}) td:nth-of-type(1) span").text
      account_available_balance = @page.css("#dashStep1 tr:nth-of-type(#{@ca_index}) td:nth-of-type(3) span").text
      account_currency = @page.css("#dashStep1 tr:nth-of-type(#{@ca_index}) td:nth-of-type(2) span").text
      ca = Accounts.new(account_name, account_available_balance, account_currency,"Credit")
      @available_accounts << ca
      @ca_index += 1
    end
  end

  #Gathers debit card information

  def gather_debit_info
    debit_accounts = @page.css("#dashStep2 tr[id]")
    @da_index = 1
    while @da_index <= debit_accounts.count do
      account_name = @page.css("#dashStep2 tr:nth-of-type(#{@da_index}) td:nth-of-type(1) span").text
      account_currency = @page.css("#dashStep2 tr:nth-of-type(#{@da_index}) td:nth-of-type(3) span").text
      account_available_balance = @page.css("#dashStep2 tr:nth-of-type(#{@da_index}) td:nth-of-type(2) span").text
      da = Accounts.new(account_name, account_currency , account_available_balance,"Debit" )
      @available_accounts << da
      @da_index += 1
    end
  end

  #Gets Last transactions payments

  def gather_last_transactions
    transactions = @page.css("#step1 > td:nth-child(5) > div[class='cellText ng-scope'] > span")
    @tr_index = 1
    while  @tr_index <= transactions.count do
      transaction_date = @page.css("#dashStep4 tr:nth-of-type(#{@tr_index}) td:nth-of-type(2)").text
      transaction_description_firstRow = @page.css("#dashStep4 tr:nth-of-type(#{@tr_index}) td:nth-of-type(3)  p:nth-child(1)").text
      transaction_description_SecondRow = @page.css("#dashStep4 tr:nth-of-type(#{@tr_index}) td:nth-of-type(3)  p:nth-child(2)").text
      transaction_amount = @page.css("#dashStep4 tr:nth-of-type(#{@tr_index}) td:nth-of-type(6) span").text
      transaction_account_name = @page.css("#dashStep4 tr:nth-of-type(#{@tr_index}) td:nth-of-type(5) span").text
      tr = Transactions.new(transaction_date, transaction_description_firstRow + " " + transaction_description_SecondRow, transaction_amount, transaction_account_name)
      @transactions_records << tr
      @tr_index += 1
    end
  end

  #Adds transactions value if Account's Name equals to last five transacrions account

  def link_transactions_to_accounts
    @available_accounts.each do |ac|
      @transactions_records.each do |tr|
        if(tr.account_name == ac.name)
          ac.transactions << tr
        end
      end
    end
    def transform_data_to_hash
      @json_hash = {"Accounts" => []}
      @available_accounts.each do |e|
        ac_hash = Hash.new()
        ac_hash["name"] = e.name
        ac_hash["balance"] = e.balance
        ac_hash["currency"] = e.currency
        ac_hash["description"] = e.nature
        ac_hash["transactions"] =[]

        e.transactions.each do |tr|
          tr_hash = Hash.new()
          tr_hash["date"] = tr.date
          tr_hash["description"] = tr.description
          tr_hash["amount"] = tr.amount

          ac_hash["transactions"].push tr_hash
        end
        @json_hash["Accounts"].push ac_hash
      end
    end


    def save(path)
      File.open(path, "w") do |f|
        f.write(JSON.pretty_generate(@json_hash.to_json))
      end
    end
  end
end