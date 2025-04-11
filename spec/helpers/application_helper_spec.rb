require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe "formatted_phone_nr" do
    subject { formatted_phone_nr(phone_nr, dialable:) }

    context "Not dialable" do
      let(:dialable) { false }

      context "10 digits without spaces" do
        let(:phone_nr) { "0901123456" }

        it "Formats the number" do
          expect(subject).to eq("0901 123 456")
        end
      end

      context "10 digits with spaces" do
        let(:phone_nr) { "  0901 12 34 56 " }

        it "Formats the number" do
          expect(subject).to eq("0901 123 456")
        end
      end

      context "With country code (and spaces)" do
        let(:phone_nr) { "+421901123 456" }

        it "Formats the number" do
          expect(subject).to eq("0901 123 456")
        end
      end

      context "Prepended (and trailing space)" do
        let(:phone_nr) { "00421901123456 " }

        it "Formats the number" do
          expect(subject).to eq("0901 123 456")
        end
      end

      context "With 2 digits" do
        let(:phone_nr) { "5 6 " }

        it "Returns empty string" do
          expect(subject).to eq("")
        end
      end

      context "With 5 digits" do
        let(:phone_nr) { " 12345" }

        it "Returns empty string" do
          expect(subject).to eq("")
        end
      end

      context "With 8 digits" do
        let(:phone_nr) { "12345678" }

        it "Returns empty string" do
          expect(subject).to eq("")
        end
      end

      context "With 9 digits" do
        let(:phone_nr) { "90112 3456" }

        it "Formats the number" do
          expect(subject).to eq("0901 123 456")
        end
      end
    end
  end
end
