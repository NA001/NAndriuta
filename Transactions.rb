class Transactions
  attr_accessor :date, :description, :amount, :account_name
  def initialize(date, description, amount, account_name)
    @date = date
    @description = description
    @amount = amount
    @account_name = account_name
  end
end