class AddCustomDocumentTypeToInvestmentDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :investment_documents, :custom_document_type, :string
  end
end
