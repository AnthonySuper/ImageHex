class AddChargedToCommissionOffer < ActiveRecord::Migration
  def change
    add_column :commission_offers,
               :charged,
               :boolean,
               default: false,
               null: false
  end
end
