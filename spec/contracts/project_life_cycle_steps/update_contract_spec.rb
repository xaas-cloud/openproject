# frozen_string_literal: true

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

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe ProjectLifeCycleSteps::UpdateContract do
  include_context "ModelContract shared context"

  let(:contract) { described_class.new(project, user) }
  let(:project) { build_stubbed(:project) }

  context "with authorized user" do
    let(:user) { build_stubbed(:user) }
    let(:project) { build_stubbed(:project, available_phases: phases) }
    let(:phases) { [] }

    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project(:edit_project_phases, project:)
      end
    end

    it_behaves_like "contract is valid"
    include_examples "contract reuses the model errors"

    describe "validations" do
      describe "#consecutive_phases_have_increasing_dates" do
        let(:phase1) { build_stubbed(:project_phase, start_date: Date.new(2024, 1, 1), finish_date: Date.new(2024, 1, 1)) }
        let(:phase2) { build_stubbed(:project_phase, start_date: Date.new(2024, 2, 1), finish_date: Date.new(2024, 2, 28)) }
        let(:phase3) { build_stubbed(:project_phase, start_date: Date.new(2024, 3, 1), finish_date: Date.new(2024, 3, 15)) }
        let(:phases) { [phase1, phase2, phase3] }

        context "when no phases are present" do
          let(:phases) { [] }

          it_behaves_like "contract is valid"
        end

        context "when only one step is present" do
          let(:phases) { [phase1] }

          it_behaves_like "contract is valid"
        end

        context "when phases have valid and increasing dates" do
          let(:phases) { [phase1, phase2, phase3] }

          it_behaves_like "contract is valid"
        end

        context "when phases have decreasing dates" do
          context "and the erroneous step is Phase 1" do
            let(:phases) { [phase3, phase1] }

            it_behaves_like "contract is invalid",
                            "available_phases.date_range": :non_continuous_dates

            it "adds an error to the decreasing step" do
              contract.validate
              expect(phase1.errors.symbols_for(:date_range)).to include(:non_continuous_dates)
            end
          end
        end

        context "when phases with identical dates" do
          let(:phase2) { build_stubbed(:project_phase, start_date: Date.new(2024, 1, 1), finish_date: Date.new(2024, 1, 1)) }

          it_behaves_like "contract is invalid",
                          "available_phases.date_range": :non_continuous_dates
        end

        context "when phases have touching start and end dates" do
          context "when 2 Phases are touching" do
            let(:phase2) { build_stubbed(:project_phase, start_date: Date.new(2024, 1, 1), finish_date: Date.new(2024, 1, 1)) }

            it_behaves_like "contract is invalid",
                            "available_phases.date_range": :non_continuous_dates

            context "when having an empty step in between" do
              let(:step_missing_dates) { build_stubbed(:project_phase, start_date: nil, finish_date: nil) }
              let(:phases) { [phase1, step_missing_dates, phase2] }

              it_behaves_like "contract is invalid",
                              "available_phases.date_range": :non_continuous_dates
            end
          end

          context "when 3 Phases are touching" do
            let(:phase2) { build_stubbed(:project_phase, start_date: Date.new(2024, 1, 1), finish_date: Date.new(2024, 1, 1)) }
            let(:phase3) { build_stubbed(:project_phase, start_date: Date.new(2024, 1, 1), finish_date: Date.new(2024, 1, 2)) }

            it_behaves_like "contract is invalid",
                            "available_phases.date_range": :non_continuous_dates

            it "adds error to Phase 2 and 3" do
              contract.validate
              expect(phase2.errors.symbols_for(:date_range)).to include(:non_continuous_dates)
              expect(phase3.errors.symbols_for(:date_range)).to include(:non_continuous_dates)
            end

            context "when having an empty step in between" do
              let(:step_missing_dates) { build_stubbed(:project_phase, start_date: nil, finish_date: nil) }
              let(:phases) { [phase1, phase2, step_missing_dates, phase3] }

              it_behaves_like "contract is invalid",
                              "available_phases.date_range": :non_continuous_dates

              it "adds error to Phase 2 and 3" do
                contract.validate
                expect(phase2.errors.symbols_for(:date_range)).to include(:non_continuous_dates)
                expect(phase3.errors.symbols_for(:date_range)).to include(:non_continuous_dates)
                expect(step_missing_dates.errors.symbols_for(:date_range)).to be_empty
              end
            end
          end
        end

        context "when a step has missing start dates" do
          let(:step_missing_dates) { build_stubbed(:project_phase, start_date: nil, finish_date: nil) }

          context "and the other phases have increasing dates" do
            let(:phases) { [phase1, step_missing_dates, phase2] }

            it_behaves_like "contract is valid"
          end

          context "and the other phases have decreasing dates" do
            let(:phases) { [phase2, step_missing_dates, phase1] }

            it_behaves_like "contract is invalid",
                            "available_phases.date_range": :non_continuous_dates

            it "adds an error to the decreasing step" do
              contract.validate
              expect(phase1.errors.symbols_for(:date_range)).to include(:non_continuous_dates)
            end
          end
        end
      end

      describe "triggering validations on the model" do
        it "sets the :saving_phases validation context" do
          allow(project).to receive(:valid?)

          contract.validate
          expect(project).to have_received(:valid?).with(:saving_phases)
        end
      end
    end
  end

  context "with unauthorized user" do
    let(:user) { build_stubbed(:user) }

    it_behaves_like "contract user is unauthorized"
  end
end
