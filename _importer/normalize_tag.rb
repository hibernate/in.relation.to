#!/usr/bin/env ruby 
# encoding: UTF-8

def normalize_tag(tag)
#  puts tag
  tags = Array.new
  tags << tag
  normalize_tags(nil, tags)[0]
end

def normalize_tags(slug, tags)

  if (tags.nil? || tags.empty?)
    temp = []
  else
    temp = tags.dup  
  end

  # Guess some tags from the slug
  temp.concat(guess_tags(slug))

  # Split "Core Relase" into "Hibernate ORM" and "Release"
  if temp.map(&:downcase).include?("core release")
    temp.push("Hibernate ORM")
    temp.push("Releases")
  end

  # Normalize the tags
  temp = temp.map{ |tag| convert_tag(tag) } 

  # Remove blacklisted tags
  temp = remove_tags(temp)

  # Remove duplicated and sort the result
  return temp.uniq.sort_by{|tag| tag.downcase}
end

def convert_tag(tag) 
  case tag
  when /hbernate/i
    "Hibernate"

  when /(Criteria queries)|(postgreSQL)|(mysql)|(Metamodel generator)|(databases)|(orm)/i
    "Hibernate ORM"

  when /Shards/i
    "Hibernate Shards"

  when /(release)|(Development)/i
    "Releases"

  when /JBoss Tools Eclipse/i
    "JBoss Tools"

  when /(seam)|(REST)|(Solder)/i
    "Seam"

  when /ceylon/i
    "Ceylon"

  when /weld/i
    "Weld"

  when /validator/i
    "Hibernate Validator"

  when /(validation)|(flex)/i
    "Bean Validation"

  when /hv51/i
    "Hibernate Validator"

  when /(Injection)|(Web Beans)|(cdi)|(ioc)|(Portable Extensions)|(Interceptors)/i
    "CDI"

  when /validation/i
    "Bean Validation"

  when /(EE)|(IceFaces)/i
    "Java EE"

  when /jboss tools eclipse/i
    "JBoss Tools"

  when /(Rich ?Faces)|(Ajax)/i
    "Rich Faces"

  when /OGM/i
    "Hibernate OGM"

  when /Forge/i
    "JBoss Forge"

  when /Weld/i
    "Weld"

  when /Photography/i
    "Off topic"

  # Look for Jboss AS but skip JBoss Asylum
  when /(Jboss as[^(ylum)])|(jboss modules)|(as7)|(jboss5)/i
    "JBoss AS"

  when /jpa/i
    "JPA"

  when /asylum/i
    "JBoss Asylum"

  when /EventListeners/i
    "Hibernate ORM"

  when /(event)|(conference)|(EclipseCon)|(openblend)|(jbug)|(keynote)|(jug)|(jbve)|(JUDCon)|(JavaOne)|(Devoxx)|(London)/i
    "Events"

  when /(discussion)|(design)|(git)|(gradle)|(maven)|(persistence)|(proposal)|(review)|(jdocbook)/i
    "Discussions"

  when /eclipse/i
    "Eclipse"

  when /(jsf)|(Java ?Server ?Faces)|(PartialViewContext)|(Mojara)/i
    "JSF"

  when /mobile/i
    "AeroGear"

  when /filters/i
    "Hibernate ORM"

  else
    tag

  end 
end

# Guess some tags from the slug
def guess_tags(slug) 
  tags = []

  if slug.nil? || slug.empty?
    return tags
  end
  
 case slug
 when /(orm)|(hibernate-?\d)/i
   tags.push("Hibernate ORM")

 when /shards/i
   tags.push("Hibernate Shards")

 when /(hibernate-search)|(full-text-search)/i
   tags.push("Hibernate Search")

 when /seam/i
   tags.push("Seam")

 when /ceylon/i
   tags.push("Ceylon")

 when /(cdi)|(injection)/i
   tags.push("CDI")

 when /(jboss-?as)|(as-?\d)/i
   tags.push("JBoss AS")

 when /(Asylum)|(podcast)/i
   tags.push("JBoss Asylum")

 when /ee/i
   tags.push("Java EE")

 when /weld/i
   tags.push("Weld")
 end
 
 return tags
end

def remove_tags(tags)
  blacklist = [ "Ajax", "Announcement", "AuthorDoclet", "Award", "BLOB",
                "Book", "Books", "Code Coverage", "Comet", "Community", "ConnectionProvider",
                "Cordova", "DeltaSpike", "Dependency Management", "Development", "Devoxx", 
                "Dukes Choice Award", "EJB", "EclEmma", "Embedded JBoss", "Errai", "EventListeners",
                "ExtendedDataTable", "Flex", "Filters", "Facelets", "Geeky Java Stuff", "Granite DS", "HTML5", "Hibernate", "Hints",
                "Interceptors", "Interoperability", "JBoss", "JBoss Portlet Bridge", "JDO", "JMS",
                "JUDCon", "JavaOne", "Jigsaw", "Jokre", "Linux", "London", "Lucene", "Maintenance", "Marshalling",
                "Mockup", "Media", "Metawidget", "Mobile", "Modules", "News", "OpenJDK", "OpenShift",
                "POH5", "Paris JUG", "Payasos", "Performance", "Portable Extensions", "Push",
                "REST", "RESTEasy", "RIA", "RFC", "ScrollableDataTable",
                "Security", "Solder", "Spring", "tattletale", "Test", "Testing", "TorqueBox", "Unified EL",
                "Versioning", "Web Frameworks", "WebSockets", "Wicket", "XML Hell", "calendar", "dataTable",
                "deployers", "vfs", "microcontainer", "dirtiness", "feature", "java",
                "jbosscentral", "jdf" ].map(&:downcase)

  return tags.reject {|tag| tag.nil? || tag.empty? || blacklist.include?(tag.strip.downcase)}
end

