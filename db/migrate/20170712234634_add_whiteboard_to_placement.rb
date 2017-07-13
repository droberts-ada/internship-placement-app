class AddWhiteboardToPlacement < ActiveRecord::Migration[5.0]
  def change
    add_column :placements, :whiteboard, :text
  end
end
