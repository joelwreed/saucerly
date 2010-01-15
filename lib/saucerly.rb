require 'java'
require 'flying_saucer'

require "action_controller"
Mime::Type.register 'application/pdf', :pdf

ActionController.add_renderer :pdf do |pdf_name, options|
  send_data_options = {:filename => pdf_name + ".pdf", :type => 'application/pdf'}
  send_data_options.merge!(options.slice(:disposition))

  html_string = render_to_string(options)

  send_data(Saucerly::Pdf.new(html_string).to_pdf, send_data_options)
end

class Saucerly::Pdf < String
  def normalize!
    gsub!(".com:/", ".com/") # strip out bad attachment_fu URLs
    gsub!(/src=["']+([^:]+?)["']/i,  %{src="#{Rails.root}/public/\\1"}) # reroute absolute paths
    gsub!(/(src=["']\S+)(\?\d*)?(["'])/i, '\1\3') # remove asset ids
  end

  def to_pdf
    normalize!
    io = StringIO.new
    ITextRenderer.new.instance_eval do
      set_document_from_string(self)
      layout
      create_pdf(io.to_outputstream)
    end
    io.string
  end
end
