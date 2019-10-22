class SetDefaultValueForCompanyEmails < ActiveRecord::Migration[5.0]
  def change
    remove_column(:companies, :emails)
    add_column(:companies, :emails, :string, default: [], required: true, array: true)
  end
end
