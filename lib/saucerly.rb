require 'java'
require 'flying_saucer'
require "action_controller"
Mime::Type.register 'application/pdf', :pdf

module Saucerly
  java_import org.xhtmlrenderer.pdf.ITextRenderer

  module Render
    def render_pdf(pdf_name, options = {})
      send_data_options = {:filename => pdf_name + ".pdf", :type => 'application/pdf'}
      send_data_options.merge!(options.slice(:disposition))
      html_string = render_to_string(options)
      send_data(Saucerly::Pdf.new(html_string).to_pdf, send_data_options)
    end
  end

  ::ActionController::Base.send :include, Saucerly::Render
  ::ActionController.add_renderer :pdf do |pdf_name, options|
    render_pdf(pdf_name, options)
  end if ::ActionController.respond_to?(:add_renderer)

  class Pdf
    def initialize(str)
      @contents = str
    end

    def normalize!
      @contents.gsub!(".com:/", ".com/") # strip out bad attachment_fu URLs
      @contents.gsub!(/src=["']+([^:]+?)["']/i,  %{src="#{Rails.root}/public/\\1"}) # reroute absolute paths
      @contents.gsub!(/(src=["']\S+)(\?\d*)?(["'])/i, '\1\3') # remove asset ids
    end

    def to_pdf
      normalize!
      io = StringIO.new
      str = @contents
      ITextRenderer.new.instance_eval do
        set_document_from_string(str)
        layout
        create_pdf(io.to_outputstream)
      end
      io.string
    end
  end
end
