require 'spec_helper'

describe WPScan::Finders::MainTheme::UrlsInHomepage do
  subject(:finder) { described_class.new(target) }
  let(:target)     { WPScan::Target.new(url) }
  let(:url)        { 'http://wp.lab/' }
  let(:fixtures)   { File.join(FINDERS_FIXTURES, 'main_theme', 'urls_in_homepage') }

  it_behaves_like 'App::Finders::WpItems::URLsInHomepage' do
    let(:type)                { 'themes' }
    let(:uniq_links)          { false }
    let(:uniq_codes)          { false }
    let(:expected_from_links) { %w[twentyfifteen twentyfifteen twentyfifteen yolo] }
    let(:expected_from_codes) { %w[test yolo] }
  end

  describe '#passive' do
    before do
      stub_request(:get, /.*.css/)
      stub_request(:get, target.url).to_return(body: File.read(File.join(fixtures, 'found.html')))
    end

    it 'returns the expected Themes' do
      @expected = []

      { 'twentyfifteen' => 6, 'yolo' => 4, 'test' => 2 }.each do |name, confidence|
        @expected << WPScan::Theme.new(
          name, target, found_by: 'Urls In Homepage (Passive Detection)', confidence: confidence
        )
      end

      expect(finder.passive).to eql @expected
    end
  end
end
