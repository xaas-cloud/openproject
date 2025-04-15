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

require_relative "../support/pages/meetings/show"

RSpec.describe "Meeting Backlogs CRUD", :js, with_flag: { meeting_backlogs: true } do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create :user,
           lastname: "First",
           preferences: { time_zone: "Etc/UTC" },
           member_with_permissions: { project => %i[view_meetings manage_agendas close_meeting_agendas] }
  end
  shared_let(:meeting) do
    create :meeting,
           project:,
           start_time: "2024-12-31T13:30:00Z",
           duration: 1.5,
           author: user
  end
  shared_let(:backlog) do
    create :meeting_section,
           backlog: true
  end

  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:wp_agenda_item) { create(:wp_meeting_agenda_item, meeting:, work_package:) }

  let(:current_user) { user }
  let(:state) { :open }
  let(:show_page) { Pages::Meetings::Show.new(meeting) }

  before do
    login_as current_user
  end

  describe "backlog visibility" do
    context "when the meeting is 'open'" do
      it "is expanded" do
        show_page.visit!
        show_page.expect_backlog collapsed: false
      end
    end

    context "when the meeting is 'in progress'" do
      before do
        meeting.update(state: :in_progress)
      end

      it "is collapsed" do
        show_page.visit!
        show_page.expect_backlog collapsed: true
      end
    end

    context "when the meeting is 'closed'" do
      before do
        meeting.update(state: :closed)
      end

      it "is not visible" do
        show_page.visit!
        show_page.expect_no_backlog
      end
    end

    context "when meeting state is changed" do
      it "collapses and expands the backlog" do
        show_page.visit!
        show_page.expect_backlog collapsed: false
        show_page.start_meeting
        show_page.expect_backlog collapsed: true
        show_page.close_meeting_from_in_progress
        show_page.reopen_meeting
        show_page.expect_backlog collapsed: false
      end
    end
  end

  # context "when items are added or removed from the backlog" do
  #   before do
  #     meeting.update(state: :in_progress)
  #   end
  #
  #   it "keeps its collapsed state and doesn't revert to the default" do
  #
  #   end
  # end
  #
  # context "when other meetings actions are done" do
  #   before do
  #     meeting.update(state: :in_progress)
  #   end
  #
  #   it "the backlog keeps its collapsed state" do
  #     show_page.visit!
  #
  #     show_page.expect_backlog collapsed: false
  #
  #     show_page.expect_backlog_count(0)
  #     show_page.expect_empty_backlog
  #
  #     show_page.add_agenda_item_to_backlog do
  #       fill_in "Title", with: "Backlog agenda item"
  #     end
  #
  #     show_page.expect_backlog_count(1)
  #     show_page.expect_backlog collapsed: false
  #     show_page.within_backlog do
  #       show_page.expect_agenda_item(title: "Backlog agenda item")
  #     end
  #
  #     wp_item = MeetingAgendaItem.find(wp_agenda_item.id)
  #     show_page.select_action(wp_item, I18n.t(:label_agenda_item_move_to_backlog))
  #
  #     show_page.expect_backlog_count(2)
  #     show_page.expect_backlog collapsed: false
  #
  #     show_page.select_action(wp_item, I18n.t(:label_agenda_item_move_to_current_meeting))
  #     show_page.expect_backlog_count(1)
  #     show_page.expect_backlog collapsed: false
  #
  #     show_page.click_on_backlog
  #     show_page.expect_backlog collapsed: true
  #   end
  # end
end
