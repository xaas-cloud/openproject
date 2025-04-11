# frozen_string_literal: true

class AddDurationToProjectPhaseJournals < ActiveRecord::Migration[8.0]
  def change
    add_column :project_phase_journals, :duration, :integer, null: true
  end
end
