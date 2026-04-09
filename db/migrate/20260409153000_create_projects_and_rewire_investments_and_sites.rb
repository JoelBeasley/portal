class CreateProjectsAndRewireInvestmentsAndSites < ActiveRecord::Migration[8.1]
  class MigrationInvestment < ApplicationRecord
    self.table_name = "investments"
  end

  class MigrationSite < ApplicationRecord
    self.table_name = "sites"
  end

  class MigrationProject < ApplicationRecord
    self.table_name = "projects"
  end

  class MigrationInvestmentSite < ApplicationRecord
    self.table_name = "investment_sites"
  end

  def up
    create_table :projects do |t|
      t.string :name, null: false
      t.text :description
      t.timestamps
    end

    add_reference :investments, :project, foreign_key: true
    add_reference :sites, :project, foreign_key: true

    MigrationInvestment.find_each do |investment|
      project_name = investment.name.presence || "Project #{investment.id}"
      project = MigrationProject.create!(name: project_name)
      investment.update_columns(project_id: project.id)

      MigrationInvestmentSite.where(investment_id: investment.id).find_each do |join_row|
        site = MigrationSite.find_by(id: join_row.site_id)
        next unless site
        next if site.project_id.present?

        site.update_columns(project_id: project.id)
      end
    end

    MigrationSite.where(project_id: nil).find_each do |site|
      fallback = MigrationProject.create!(name: site.name.presence || "Project for Site #{site.id}")
      site.update_columns(project_id: fallback.id)
    end

    change_column_null :investments, :project_id, false
    change_column_null :sites, :project_id, false

    drop_table :investment_sites
  end

  def down
    create_table :investment_sites do |t|
      t.references :investment, null: false, foreign_key: true
      t.references :site, null: false, foreign_key: true
      t.timestamps
    end

    remove_reference :sites, :project, foreign_key: true
    remove_reference :investments, :project, foreign_key: true
    drop_table :projects
  end
end
