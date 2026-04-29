# Updates existing Site rows when `name` matches known Digital Midstream sites.
# Status integers match Site enum: operating=0, construction=1, development=2, paused=3
class BackfillSiteDetailsByName < ActiveRecord::Migration[8.1]
  def up
    say_with_time "Backfill site details by name" do
      rows = [
        {
          name: "Liberty Point",
          location: "TN",
          power_source: "Natural Gas / Ethane",
          model: "BTC Mining / CO2",
          size_kw: 8350,
          status: 3,
          power_cost: -0.04
        },
        {
          name: "Hailey's Mill",
          location: "KY",
          power_source: "Natural Gas",
          model: "BTC Mining",
          size_kw: 1500,
          status: 1,
          power_cost: 0.02
        },
        {
          name: "Bluegrass",
          location: "KY",
          power_source: "Natural Gas",
          model: "BTC Mining",
          size_kw: 1500,
          status: 2,
          power_cost: 0.01
        },
        {
          name: "Hash Dock",
          location: "KY",
          power_source: "Grid",
          model: "BTC Mining",
          size_kw: nil,
          status: 0,
          power_cost: 0.08
        }
      ]

      now = Time.current
      total = 0
      rows.each do |row|
        name = row.fetch(:name)
        attrs = row.except(:name).merge(updated_at: now)
        total += Site.where(name: name).update_all(attrs)
      end
      total
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
