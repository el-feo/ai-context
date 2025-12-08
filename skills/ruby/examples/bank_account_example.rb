# frozen_string_literal: true

# Example Ruby Application - Demonstrating Best Practices
# This file showcases patterns and practices from the Ruby skill

# Custom exceptions for domain logic
class PaymentError < StandardError; end
class InsufficientFundsError < PaymentError; end
class InvalidCardError < PaymentError; end

# Result object pattern for error handling
class Result
  attr_reader :value, :error

  def initialize(value: nil, error: nil)
    @value = value
    @error = error
  end

  def success?
    error.nil?
  end

  def failure?
    !success?
  end
end

# Main domain class with proper encapsulation
class BankAccount
  attr_reader :account_number, :balance

  MIN_BALANCE = 0
  MAX_BALANCE = 1_000_000

  def initialize(account_number:, initial_balance: 0)
    @account_number = account_number
    @balance = initial_balance
    validate_balance!
  end

  # Predicate method
  def active?
    balance.positive?
  end

  # Main business logic with explicit error handling
  def withdraw(amount)
    return Result.new(error: "Amount must be positive") if amount <= 0
    return Result.new(error: "Insufficient funds") if amount > balance

    @balance -= amount
    Result.new(value: balance)
  end

  def deposit(amount)
    return Result.new(error: "Amount must be positive") if amount <= 0
    return Result.new(error: "Exceeds maximum balance") if balance + amount > MAX_BALANCE

    @balance += amount
    Result.new(value: balance)
  end

  # Public interface method with guard clauses
  def transfer_to(target_account, amount)
    return false unless target_account.is_a?(BankAccount)
    return false if amount <= 0

    result = withdraw(amount)
    return false if result.failure?

    target_result = target_account.deposit(amount)
    if target_result.failure?
      # Rollback
      deposit(amount)
      return false
    end

    true
  end

  # Memoization for expensive computation
  def account_type
    @account_type ||= calculate_account_type
  end

  private

  def validate_balance!
    raise ArgumentError, "Balance cannot be negative" if balance < MIN_BALANCE
    raise ArgumentError, "Balance exceeds maximum" if balance > MAX_BALANCE
  end

  def calculate_account_type
    case balance
    when 0...1_000
      :basic
    when 1_000...10_000
      :silver
    when 10_000...100_000
      :gold
    else
      :platinum
    end
  end
end

# Strategy pattern for transaction processing
module TransactionStrategy
  class Standard
    def process_fee(amount)
      amount * 0.01 # 1% fee
    end
  end

  class Premium
    def process_fee(amount)
      amount * 0.005 # 0.5% fee
    end
  end

  class Free
    def process_fee(_amount)
      0 # No fee
    end
  end
end

# Composition over inheritance
module Auditable
  def audit_log
    @audit_log ||= []
  end

  def log_action(action, details)
    audit_log << {
      timestamp: Time.now,
      action: action,
      details: details
    }
  end
end

class Transaction
  include Auditable

  attr_reader :id, :from_account, :to_account, :amount, :status

  def initialize(from_account:, to_account:, amount:, strategy: TransactionStrategy::Standard.new)
    @id = SecureRandom.uuid
    @from_account = from_account
    @to_account = to_account
    @amount = amount
    @strategy = strategy
    @status = :pending
  end

  # Endless method (Ruby 3.0+)
  def fee = @strategy.process_fee(amount)
  def total_amount = amount + fee

  def execute
    log_action(:execute_started, { amount: amount, fee: fee })

    return failure_result("Insufficient funds") unless from_account.withdraw(total_amount).success?
    return failure_result("Deposit failed") unless to_account.deposit(amount).success?

    @status = :completed
    log_action(:execute_completed, { status: @status })
    success_result
  rescue StandardError => e
    log_action(:execute_failed, { error: e.message })
    @status = :failed
    raise
  end

  private

  def success_result
    Result.new(value: { id: id, status: status })
  end

  def failure_result(message)
    @status = :failed
    log_action(:failure, { reason: message })
    Result.new(error: message)
  end
end

# Builder pattern for complex object creation
class TransactionBuilder
  def initialize
    @transaction_params = {}
  end

  def from_account(account)
    @transaction_params[:from_account] = account
    self
  end

  def to_account(account)
    @transaction_params[:to_account] = account
    self
  end

  def amount(amount)
    @transaction_params[:amount] = amount
    self
  end

  def with_premium_strategy
    @transaction_params[:strategy] = TransactionStrategy::Premium.new
    self
  end

  def with_free_strategy
    @transaction_params[:strategy] = TransactionStrategy::Free.new
    self
  end

  def build
    validate_params!
    Transaction.new(**@transaction_params)
  end

  private

  def validate_params!
    required = %i[from_account to_account amount]
    missing = required.reject { |key| @transaction_params.key?(key) }
    raise ArgumentError, "Missing required parameters: #{missing.join(', ')}" if missing.any?
  end
end

# Example usage
def demonstrate_bank_system
  puts "=== Bank Account System Demo ==="
  puts

  # Create accounts
  account1 = BankAccount.new(account_number: "ACC001", initial_balance: 1000)
  account2 = BankAccount.new(account_number: "ACC002", initial_balance: 500)

  puts "Initial balances:"
  puts "Account 1: $#{account1.balance} (#{account1.account_type})"
  puts "Account 2: $#{account2.balance} (#{account2.account_type})"
  puts

  # Simple transfer
  puts "--- Simple Transfer ---"
  success = account1.transfer_to(account2, 200)
  puts "Transfer #{success ? 'succeeded' : 'failed'}"
  puts "Account 1: $#{account1.balance}"
  puts "Account 2: $#{account2.balance}"
  puts

  # Transaction with builder pattern and strategy
  puts "--- Transaction with Builder ---"
  transaction = TransactionBuilder.new
                  .from_account(account2)
                  .to_account(account1)
                  .amount(100)
                  .with_premium_strategy
                  .build

  puts "Transaction ID: #{transaction.id}"
  puts "Amount: $#{transaction.amount}"
  puts "Fee: $#{transaction.fee}"
  puts "Total: $#{transaction.total_amount}"

  result = transaction.execute
  if result.success?
    puts "Transaction completed successfully"
    puts "Final balances:"
    puts "Account 1: $#{account1.balance}"
    puts "Account 2: $#{account2.balance}"
  else
    puts "Transaction failed: #{result.error}"
  end
  puts

  # Show audit log
  puts "--- Audit Log ---"
  transaction.audit_log.each do |entry|
    puts "#{entry[:timestamp]} - #{entry[:action]}: #{entry[:details]}"
  end
end

# Pattern matching example (Ruby 2.7+)
def process_transaction_status(transaction)
  case transaction
  in { status: :completed, amount: amount } if amount > 1000
    "Large transaction completed: $#{amount}"
  in { status: :completed, amount: amount }
    "Transaction completed: $#{amount}"
  in { status: :pending }
    "Transaction is pending"
  in { status: :failed, error: error }
    "Transaction failed: #{error}"
  else
    "Unknown transaction status"
  end
end

# Run the demonstration
demonstrate_bank_system if __FILE__ == $PROGRAM_NAME
