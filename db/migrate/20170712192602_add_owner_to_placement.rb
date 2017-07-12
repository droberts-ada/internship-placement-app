class AddOwnerToPlacement < ActiveRecord::Migration[5.0]
  def change
    add_reference :placements, :owner, references: :users, index: true
    add_foreign_key :placements, :users, column: :owner_id
  end
end
