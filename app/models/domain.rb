require 'rubygems'
require 'nokogiri'
# require 'whois'
require 'open-uri'
require 'resolv'
load "suffix_array.rb"
load "prefix_array.rb"

class Domain < ActiveRecord::Base

@suffixArray = ['Aa', 'Aaa']
@prefixArray = ['Aa', 'Aaa']

@res = Hash.new
  def self.ask_whois_dotnet(query)
    begin
      doc = Nokogiri::HTML(open('http://www.whois.com/whois/'+query,'User-Agent' => 'ruby'))
      linkArray = []
      doc.xpath('//div/h1/span').each do |link|
        linkArray.push(link.content)
      end
      $whoisdotnetcounter += 1
      if(linkArray[0] == "available")
        puts "AVAILABLE: " + query
        $avail.push(query)
        return true
      elsif(linkArray[0] == "not available")
        puts "not available: " + query
        return false
      end
    rescue Timeout::Error
      retry #timeout, no info gained, retry?
    end
  end

  def self.http_check_domain(query)
    begin
      entry = Resolv.getaddress(query)
    rescue Resolv::ResolvError
      return false #dns could not resolve, may still be registered
    rescue Timeout::Error
      retry #timeout, no info gained, retry?
    end
    if entry
      #$httpcounter += 1
      return true #yes, domain is registered
    else
      return false #not sure why it would fail, so lets fail out of this f'n
    end
  end

  def self.checkDomain(dom)
    if (http_check_domain(dom)) #if exists - this passes, and we'll return false out of this f'n
      puts "not available: " + dom
      return false #domain not available, false
    else
      begin
        $c = Whois::Client.new(:timeout => nil)
         r = $c.lookup(dom)
        $whoiscounter += 1
         if (r.available?)
          puts "AVAILABLE: " + dom
          $avail.push(dom) #yes, true, domain is available
          return true
         else
          puts "not available: " + dom
          return false #domain not available, false
         end
      rescue
        whoisdotnet = ask_whois_dotnet(dom)
        return whoisdotnet
      end
     end
  end

  def self.get_root_domains(q)
    prefixs = %w(.com .org .net .co .io .ly)
    threads = [] 
    for prefix in prefixs 
         threads << Thread.new(prefix) do |prefix| 
          @res[q+prefix] = checkDomain(q+prefix)
         end
    end 
    threads.each { |aThread| aThread.join } 
  end

  def self.domainblob_main(search_item)
    
    thePhrase = search_item
      $whoiscounter = 0
      $httpcounter = 0
      $whoisdotnetcounter = 0
      $avail = []
      
      thePhrase.capitalize!
      thePhrase.strip!
      timeThen = Time.now
      get_root_domains(thePhrase)
      #now go through prefixes, then suffixes for this phrase   
      for each in @prefixArray
        @res[each+thePhrase+'.com'] = checkDomain(each + thePhrase + ".com")
      end
      for each in @suffixArray
       @res[thePhrase+each+'.com'] = checkDomain(thePhrase + each + ".com")
      end
    return @res
  end
  
end
