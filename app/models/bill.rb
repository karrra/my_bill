include QueryItemType

class Bill < ActiveRecord::Base
  belongs_to :user
  has_many :items

  def add_item(content, msg_id)
    return true if Item.exists?(msg_id: msg_id)
    i_type = QueryItemType.get(content)
    return false unless i_type
    memo, amount = content.split(' ')
    return false unless amount

    Item.transaction do
      Item.create(
        bill_id: self.id,
        memo: memo,
        parent_type_id: i_type[:parent].id,
        parent_type_name: i_type[:parent].name,
        child_type_id: i_type[:child].id,
        child_type_name: i_type[:child].name,
        record_at: Time.current,
        inorout: i_type[:incomes],
        amount: amount,
        msg_id: msg_id
      )
    end
  end

  def total_expense(type='month')
    the_items = items.expense
    get_result(the_items, type)
  end

  def total_incomes(type='month')
    the_items = items.incomes
    get_result(the_items, type)
  end

  def weekly_report
    group_items = items.expense.week.select(:parent_type_name, :amount).group_by(&:parent_type_name)
    group_items.map do |k, v|
      "#{k}: #{v.sum(&:amount).round(2)} 元"
    end.join("\n")
  end

  def daily_report
    group_items = items.expense.day.select(:parent_type_name, :amount).group_by(&:parent_type_name)
    group_items.map do |k, v|
      "#{k}: #{v.sum(&:amount).round(2)} 元"
    end.join("\n")
  end

  def get_result(items, type)
    case type
    when 'month'
      items.month.sum(:amount)
    when 'week'
      items.week.sum(:amount)
    when 'day'
      items.day.sum(:amount)
    end
  end
end
