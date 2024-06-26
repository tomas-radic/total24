class CreateMatches < ActiveRecord::Migration[7.1]
  def change
    create_table :matches, id: :uuid do |t|
      t.date :play_date
      t.integer :play_time
      t.string :notes
      t.integer :kind, null: false, default: 0
      t.datetime :published_at
      t.integer :winner_side
      t.datetime :requested_at
      t.datetime :accepted_at
      t.datetime :rejected_at
      t.datetime :reviewed_at
      t.datetime :finished_at
      t.boolean :ranking_counted, null: false, default: true
      t.references :competitable, polymorphic: true, null: false, type: :uuid
      t.references :place, foreign_key: true, type: :uuid
      t.integer :set1_side1_score
      t.integer :set1_side2_score
      t.integer :set2_side1_score
      t.integer :set2_side2_score
      t.integer :set3_side1_score
      t.integer :set3_side2_score

      t.timestamps
    end
  end
end
