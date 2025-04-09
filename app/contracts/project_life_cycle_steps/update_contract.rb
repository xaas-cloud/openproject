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
  class UpdateContract < BaseContract
    validate :consecutive_steps_have_increasing_dates

    alias_method :project, :model

    def valid?(context = :saving_phases) = super

    def consecutive_steps_have_increasing_dates
      # Filter out steps with missing dates before proceeding with comparison
      filtered_steps = model.available_phases.select(&:range_set?)

      # Compare consecutive steps in pairs
      filtered_steps.each_cons(2) do |previous_step, current_step|
        unless valid_dates?(previous_step, current_step)
          error = current_step.errors.add(:date_range, :non_continuous_dates)
          unless model.errors.include?(:"available_phases.date_range")
            model.errors.import(error, attribute: :"available_phases.date_range")
          end
        end
      end
    end
  end
end
