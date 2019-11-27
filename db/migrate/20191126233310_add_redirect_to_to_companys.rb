class AddRedirectToToCompanys < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :redirect_to, :uuid
  end
end
