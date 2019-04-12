class Transaction
  attr_accessor :date, :description, :amount, :account_name, :currency
  def initialize(date, description, amount, account_name ,currency)
    @date = date
    @description = description
    @amount = amount
    @account_name = account_name
    @currency = currency
  end
end