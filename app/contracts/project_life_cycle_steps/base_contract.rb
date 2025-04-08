#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module ProjectLifeCycleSteps
  class BaseContract < ::ModelContract
    validate :edit_project_phases_permission
    validate :consecutive_steps_have_increasing_dates

    def valid?(context = :saving_phases) = super

    def edit_project_phases_permission
      return if user.allowed_in_project?(:edit_project_phases, model)

      errors.add :base, :error_unauthorized
    end

    def consecutive_steps_have_increasing_dates
      # Filter out steps with missing dates before proceeding with comparison
      filtered_steps = model.available_phases.select(&:start_date)

      # Compare consecutive steps in pairs
      filtered_steps.each_cons(2) do |previous_step, current_step|
        if has_invalid_dates?(previous_step, current_step)
          error = current_step.errors.add(:date_range, :non_continuous_dates)
          unless model.errors.include?(:"available_phases.date_range")
            model.errors.import(error, attribute: :"available_phases.date_range")
          end
        end
      end
    end

    private

    def start_date_for(step)
      step.start_date
    end

    def finish_date_for(step)
      step.finish_date || step.start_date # Use the start_date as fallback for single date stages
    end

    def has_invalid_dates?(previous_step, current_step)
      start_date_for(current_step) <= finish_date_for(previous_step)
    end
  end
end
