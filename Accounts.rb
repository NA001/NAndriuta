
class Accounts
  attr_accessor :name, :currency, :balance, :nature, :transactions
  def initialize(name, currency, balance, nature)
    @name = name
    @currency = currency
    @balance = balance
    @nature = nature
    @transactions = []
  end
end

