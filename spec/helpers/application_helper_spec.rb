require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '#icon' do
    subject(:icon) { helper.icon('check') }

    before do
      allow(helper).to receive(:render)
      icon
    end

    context 'when no css_class is given' do
      it 'renders the matching icon partial with the default classes' do
        expect(helper).to have_received(:render).with('shared/icons/check', css_class: 'size-4 shrink-0')
      end
    end

    context 'when a css_class is given' do
      subject(:icon) { helper.icon('check', css_class: 'size-6') }

      it 'renders the matching icon partial with the given classes' do
        expect(helper).to have_received(:render).with('shared/icons/check', css_class: 'size-6')
      end
    end
  end

  describe '#icon_label' do
    subject(:icon_label) { helper.icon_label('check', 'Save') }

    before { allow(helper).to receive(:icon) }

    it 'renders the icon for the given name' do
      icon_label
      expect(helper).to have_received(:icon).with('check')
    end

    it 'renders the label text in a span' do
      expect(icon_label).to include('<span>Save</span>')
    end
  end

  describe '#nav_link_to' do
    subject(:nav_link_to) { helper.nav_link_to('Employees', '/employees', 'employees') }

    before { allow(helper).to receive(:controller_name).and_return(controller_name) }

    context 'when the current controller matches' do
      let(:controller_name) { 'employees' }

      it 'sets aria-current to page' do
        expect(nav_link_to).to include('aria-current="page"')
      end

      it 'applies the active text class' do
        expect(nav_link_to).to include('text-nav-active')
      end
    end

    context 'when the current controller does not match' do
      let(:controller_name) { 'exchange_rates' }

      it 'omits aria-current' do
        expect(nav_link_to).not_to include('aria-current')
      end

      it 'applies the inactive text class' do
        expect(nav_link_to).to include('text-nav-text')
      end
    end
  end

  describe '#aggregated_amount' do
    context 'when the value is nil' do
      subject(:aggregated_amount) { helper.aggregated_amount(nil) }

      it 'renders an em dash placeholder' do
        expect(aggregated_amount).to include('—')
      end

      it 'applies the muted text class' do
        expect(aggregated_amount).to include('text-text-muted')
      end
    end

    context 'when the value is present' do
      subject(:aggregated_amount) { helper.aggregated_amount(85_000) }

      it 'formats the amount with two decimal places and a thousands delimiter' do
        expect(aggregated_amount).to include('85,000.00')
      end

      it 'labels the amount as USD' do
        expect(aggregated_amount).to include('USD')
      end
    end
  end

  describe '#truncated_text' do
    subject(:truncated_text) { helper.truncated_text('Software Engineer', css_class: 'w-40') }

    it 'renders the value as the visible text' do
      expect(truncated_text).to include('>Software Engineer<')
    end

    it 'applies the truncate class along with the given class' do
      expect(truncated_text).to include('class="truncate w-40"')
    end

    it 'exposes the full value through the title attribute' do
      expect(truncated_text).to include('title="Software Engineer"')
    end

    it 'exposes the full value through the aria-label attribute' do
      expect(truncated_text).to include('aria-label="Software Engineer"')
    end
  end
end
