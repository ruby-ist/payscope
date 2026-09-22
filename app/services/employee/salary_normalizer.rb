class Employee
  class SalaryNormalizer
    def initialize(local_salary, exchange_rate)
      @local_salary = local_salary
      @exchange_rate = exchange_rate
    end

    def normalized_usd_salary
      (BigDecimal(@local_salary.to_s) * BigDecimal(@exchange_rate.rate.to_s)).round(2)
    end
  end
end
