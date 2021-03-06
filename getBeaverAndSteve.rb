require 'mechanize'
require 'logger'
require 'pry'
require 'zip/zip'

class GetBeaverAndSteve
  attr_accessor :agent, :first_page, :chapter_markers

  def initialize()
    @agent = Mechanize.new
    @agent.log = Logger.new "mech.log"
    @agent.user_agent_alias = 'Mac Safari'
  end

  def start_download
    # Start with first page of first Chapter
    base_url = "http://www.beaverandsteve.com/"
    page = @agent.get("#{base_url}index.php?comic=1")
    puts @agent.current_page().uri()

    keep_going = true
    current_chapter = 1
    page_cursor = 1
    while keep_going
      page = @agent.current_page()
      if page_cursor % 25 == 0
        zip_previous_chapter(current_chapter)
        current_chapter = current_chapter + 1
        puts "Chapter switched to -> " + current_chapter.to_s
      end

      comic_url = page.search("//img[contains(@src,'comics')]").first.attributes["src"].to_s
      image_name = comic_url.split('/')[-1]
      @agent.get("http://www.beaverandsteve.com/#{comic_url}").save("#{chapter_directory(current_chapter)}/#{page_cursor}_#{image_name}")
      puts "Currently Downloading: #{current_chapter}"
      puts "Downloading comic address: #{comic_url}"

      next_link = page.search("//a/img[@id='next']").first
      if next_link.respond_to? :parent
        next_link_parent = next_link.parent
        next_url = next_link_parent.attributes["href"].to_s
        next_page = @agent.get("#{base_url}#{next_url}")
      else
        zip_previous_chapter(current_chapter)
        keep_going = false
      end
      page_cursor = page_cursor + 1
    end
  end

  def chapter_directory(chapter_id)
    "beaverandsteve_comics/bns_chapter_#{chapter_id}"
  end

  def zip_file_path(chapter_id)
    directory_name = "saved_comics"
    unless File.directory?(directory_name)
      FileUtils.mkdir_p(directory_name)
    end
    "#{directory_name}/bns_chapter_#{chapter_id}.cbz"
  end

  def zip_previous_chapter(chapter_id)
    directory = chapter_directory(chapter_id)
    zipfile_name = zip_file_path(chapter_id)
    if File.exist?(zipfile_name)
      File.delete(zipfile_name)
    end
    Zip::ZipFile.open(zipfile_name, 'w') do |zipfile|
      Dir["#{directory}/**/**"].reject{|f|f==zipfile_name}.each do |file|
        zipfile.add(file.sub(directory+'/',''),file)
      end
    end
  end

  class << self
    def new_download()
      scary_downloader = self.new()
      scary_downloader.start_download
    end
  end

end

GetBeaverAndSteve.new_download()

exit
