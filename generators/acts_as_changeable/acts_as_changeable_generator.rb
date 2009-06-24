class ActsAsChangeableGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      # m.dependency("acts_as_changeset", [], options)
      destination = (options[:destination] || Rails.root)
      puts "\tfind db/migrate/*_create_#{file_name.pluralize}.rb"
      file_glob = File.join(destination, "db", "migrate", "*_create_#{file_name.pluralize}.rb")
      possible_files = Dir.glob(file_glob)
      if(possible_files.size > 0)
        matches = []
        File.read(possible_files.first).each do |line|
          matches << [$1, $3, $4] if line =~ /^\s*t.(\w+)(\s+:(\w+)(.*))?$/
        end
        args = ["#{class_name}History", "changeset_id:string"]
        matches.each do |arg| 
          arg[1] = "#{file_name}_id" if arg[1] == 'id'
          args << "#{arg[1]}:#{arg[0]}" unless arg[1].nil?
        end 
        m.dependency("resource", args)
        m.acts_as_changeable
        m.acts_as_changeable_history
        # m.file "definition.txt", "definition.txt"
      else
        puts "Error - I couldn't find a matching migration. Bailing out!"
      end
    end
  end

end