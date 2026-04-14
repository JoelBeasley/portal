class CreateInvestmentDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :investment_documents do |t|
      t.references :investment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :document_type, null: false

      t.timestamps
    end
  end
end
