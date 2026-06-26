class ChangePercentOfClassByTotalRaisedPrecision < ActiveRecord::Migration[8.1]
  def change
    change_column :investments, :percent_of_class_by_total_raised, :decimal, precision: 8, scale: 2
  end
end
