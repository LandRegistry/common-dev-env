require 'fileutils'

def delete_files(root_loc)
  FileUtils.rm_f "#{root_loc}/.commodities.yml"
  FileUtils.rm_f "#{root_loc}/.custom_provision.yml"
  FileUtils.rm_f "#{root_loc}/.docker-compose-file-list"
  FileUtils.rm_f "#{root_loc}/.db2_init.sql"
  FileUtils.rm_f "#{root_loc}/.postgres_init.sql"
end
