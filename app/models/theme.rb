module WPScan
  # WordPress Theme
  class Theme < WpItem
    attr_reader :style_url, :style_name, :style_uri, :author, :author_uri, :template, :description,
                :license, :license_uri, :tags, :text_domain

    # See WpItem
    def initialize(name, target, opts = {})
      super(name, target, opts)

      @uri       = Addressable::URI.parse(target.url("wp-content/themes/#{name}/"))
      @style_url = opts[:style_url] || url('style.css')

      parse_style
    end

    # @param [ Hash ] opts
    #
    # @return [ WPScan::Version, false ]
    def version(opts = {})
      @version = Finders::ThemeVersion::Base.find(self, detection_opts.merge(opts)) if @version.nil?

      @version
    end

    # @return [ Array<Vulneraility> ]
    def vulnerabilities
      DB::Theme.vulnerabilities(self)
    end

    # @return [ Theme ]
    def parent_theme
      return unless template
      return unless style_body =~ /^@import\surl\(["']?([^"'\)]+)["']?\);\r?$/i

      opts = detection_opts.merge(
        style_url: url(Regexp.last_match[1]),
        found_by: 'Parent Themes (Passive Detection)',
        confidence: 100
      )

      self.class.new(template, target, opts)
    end

    # @param [ Integer ] depth
    #
    # @retun [ Array<Theme> ]
    def parent_themes(depth = 3)
      theme  = self
      found  = []

      (1..depth).each do |_|
        parent = theme.parent_theme

        break unless parent

        found << parent
        theme = parent
      end

      found
    end

    def style_body
      @style_body ||= Browser.get(style_url).body
    end

    def parse_style
      {
        style_name: 'Theme Name',
        style_uri: 'Theme URI',
        author: 'Author',
        author_uri: 'Author URI',
        template: 'Template',
        description: 'Description',
        license: 'License',
        license_uri: 'License URI',
        tags: 'Tags',
        text_domain: 'Text Domain'
      }.each do |attribute, tag|
        instance_variable_set(:"@#{attribute}", parse_style_tag(style_body, tag))
      end
    end

    # @param [ String ] bofy
    # @param [ String ] tag
    #
    # @return [ String ]
    def parse_style_tag(body, tag)
      value = body[/^\s*#{Regexp.escape(tag)}:\s*(.*)/i, 1]

      value.strip if value
    end

    def ==(other)
      super(other) && style_url == other.style_url
    end
  end
end
